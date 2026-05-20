#!/usr/bin/env python3
"""
ensure-template-configs.py

Converts JSON configuration files to HCL2 for Packer templates.
Supports incremental conversion using a single .conversion-state.json file.
"""

import argparse
import hashlib
import json
import logging
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List

# =============================================================================
# Configuration
# =============================================================================
SCRIPT_VERSION = "2026.5.10"
CACHE_FILE = Path(".conversion-state.json")
TEMPLATE_DIR = Path("templates")

# Directories/files to exclude
EXCLUDE_PATTERNS = ["**/archive/**", "**/save/**", "**/backup/**", "**/.git/**"]

# Files to INCLUDE (matching original config.sh behavior)
INCLUDE_PATTERNS = [
    "**/distribution-vars.json",
    "**/box_info.*.json",
    "**/template*.json",
    "**/build-config*.json"
]

DEFAULT_DISTRIBUTIONS = [
    "CentOS,8", "CentOS,9", "CentOS,10",
    "Debian,10", "Debian,11", "Debian,12",
    "RHEL,8", "RHEL,9",
    "Ubuntu,22.04", "Ubuntu,24.04", "Ubuntu,26.04",
    "Windows/server,2016", "Windows/server,2019", "Windows/server,2022",
    "Windows/desktop,10", "Windows/desktop,11"
]


# =============================================================================
# Logging Configuration
# =============================================================================
def setup_logging(log_level: str = "INFO"):
    numeric_level = getattr(logging, log_level.upper(), None)
    if not isinstance(numeric_level, int):
        numeric_level = logging.INFO

    logging.basicConfig(
        level=numeric_level,
        format="[%(levelname)-8s] %(message)s"
    )


def get_file_hash(file_path: Path) -> str:
    """Return SHA256 hash of a file, or 'MISSING' if file doesn't exist."""
    if not file_path.exists():
        return "MISSING"
    return hashlib.sha256(file_path.read_bytes()).hexdigest()


def load_state() -> Dict:
    """Load conversion state from cache file."""
    if CACHE_FILE.exists():
        try:
            return json.loads(CACHE_FILE.read_text())
        except Exception:
            logging.warning("Failed to load conversion state cache")
    return {}


def save_state(state: Dict):
    """Save conversion state to cache file."""
    try:
        CACHE_FILE.write_text(json.dumps(state, indent=2, sort_keys=True))
    except Exception as e:
        logging.error(f"Failed to save conversion state: {e}")


def run_command(cmd: list):
    """Run a shell command and return result."""
    logging.debug(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        logging.error(f"Command failed: {' '.join(cmd)}")
        logging.error(result.stderr)
        sys.exit(1)
    return result


def get_hcl_output_path(json_path: Path, file_type: str) -> Path:
    """Preserve original stem: box_info.large.json → box_info.json.large.pkrvars.hcl"""
    if file_type in ("vars"):
        return json_path.with_name(f"{json_path.stem}.json.pkrvars.hcl")
    else:
        # build files
        return json_path.with_name(f"{json_path.stem}.json.pkr.hcl")


def convert_json_to_hcl(json_path: Path, file_type: str = "vars", build_platform: str = "", backup: bool = False):
    """Convert JSON to HCL with Unix line endings."""
    hcl_path = get_hcl_output_path(json_path, file_type)

    # Show relative path from template root for easier debugging
    rel_path = json_path.relative_to(TEMPLATE_DIR)
    logging.debug(f"Converting {rel_path} → {hcl_path.name} (type: {file_type})")

    # Optional backup
    if backup and hcl_path.exists():
        backup_path = hcl_path.with_suffix(hcl_path.suffix + ".bak")
        shutil.copy2(hcl_path, backup_path)
        logging.debug(f"Backed up to {backup_path.name}")

    if file_type in ("vars"):
        # Special handling for variable files
        data = json.loads(json_path.read_text())
        with open(hcl_path, "w", encoding="utf-8", newline="\n") as f:
            for k, v in data.items():
                # Escape properly for HCL
                if isinstance(v, str):
                    escaped = v.replace('\\', '\\\\').replace('"', '\\"')
                    f.write(f'{k}="{escaped}"\n')
                else:
                    f.write(f'{k}={json.dumps(v)}\n')
    else:
        # packer hcl2_upgrade for build files
        run_command(["packer", "hcl2_upgrade", "-output-file", str(hcl_path),
                     "-with-annotations", str(json_path)])

    # Post-processing (common to all)
    content = hcl_path.read_text(encoding="utf-8")

    # 2. Convert $$ to $
    # Bash: sed -i 's|\$\$|\$|g'
    content = content.replace("$$", "$")

    # 3. Convert \" to " (Unescape quotes)
    # Bash: sed -i 's|\\\"|\"|g'
    content = content.replace('\\"', '"')

    # 4. Remove surrounding quotes from %% patterns [cite: 145, 146]
    # Bash: sed -i 's|"%%\(.*\)"|\1|g'
    # This turns "%%var.name" into var.name
    content = re.sub(r'"%%(.*)"', r'\1', content)

    # Replace autogenerated_XXX with just the platform name (e.g. Ubuntu)
    if file_type == "build" and build_platform:
        content = re.sub(r'autogenerated_\d+', build_platform, content)

    # Write with explicit Unix (LF) line endings
    hcl_path.write_text(content, encoding="utf-8", newline="\n")

    logging.info(f"✓ Converted {json_path.name} → {hcl_path.name}")


def link_common_hcl_files(dist_dir: Path):
    """Link common .hcl files from root into distribution directory."""
    for hcl_file in TEMPLATE_DIR.glob("*.hcl"):
        if any(skip in hcl_file.name for skip in ["env-vars", ".pkrvars", ".pkr.hcl", "common-vars"]):
            continue
        target = dist_dir / hcl_file.name
        if target.exists():
            target.unlink()
        target.symlink_to(hcl_file.relative_to(dist_dir))
        logging.debug(f"Linked: {hcl_file.name}")


def find_json_files(dist_dir: Path, version_dir: Path) -> List[Path]:
    """Distribution level + version level files only."""
    json_files = []

    # 1. Distribution level files
    if dist_dir.exists():
        for pattern in ["distribution-vars.json", "build-config*.json"]:
            json_files.extend(dist_dir.glob(pattern))

    # 2. Version level files
    if version_dir.exists() and version_dir != dist_dir:
        for json_file in version_dir.rglob("*.json"):
            if any(json_file.match(p) for p in EXCLUDE_PATTERNS):
                continue
            if any(json_file.match(p) for p in INCLUDE_PATTERNS):
                json_files.append(json_file)

    return sorted(set(json_files))


def main():
    parser = argparse.ArgumentParser(description="Ensure Packer template configs are up-to-date")
    parser.add_argument("-L", "--log-level",
                        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
                        default="INFO",
                        help="Set logging level (default: INFO)")
    parser.add_argument("--clear-cache", action="store_true", help="Clear conversion cache")
    parser.add_argument("--force", action="store_true", help="Force full conversion")
    parser.add_argument("--backup", action="store_true", help="Create .bak files")
    parser.add_argument("dist_list", nargs="*", help="Specific distributions (e.g. Ubuntu,24.04)")
    args = parser.parse_args()

    setup_logging(args.log_level)
    logging.info(f"ensure-template-configs.py v{SCRIPT_VERSION} started")

    if args.clear_cache and CACHE_FILE.exists():
        CACHE_FILE.unlink()
        logging.info("Conversion cache cleared.")
        return

    state = load_state()

    # Default distribution list
    dist_list = args.dist_list or DEFAULT_DISTRIBUTIONS

    # Common vars as vardef
    common_vars = TEMPLATE_DIR / "common-vars.json"
    if common_vars.exists():
        convert_json_to_hcl(common_vars, "vardef", backup=args.backup)

    # Process each distribution
    for dist_info in dist_list:
        parts = dist_info.split(",")
        dist_name = parts[0]
        dist_version = parts[1] if len(parts) > 1 else ""

        dist_dir = TEMPLATE_DIR / dist_name
        version_dir = dist_dir / dist_version if dist_version else dist_dir

        logging.info(f"Processing distribution: {dist_info}")

        # e.g. "Windows/server" → "Windows", "Ubuntu" → "Ubuntu"
        build_platform = dist_name.split("/")[0]

        # Link common HCL files
        link_common_hcl_files(dist_dir)

        # Find JSON files (excluding archive/save/etc.)
        json_files = find_json_files(dist_dir, version_dir)

        for json_file in json_files:
            rel_path = str(json_file.relative_to(TEMPLATE_DIR))
            file_type = "build" if "build-config" in json_file.name else "vars"

            # Check if conversion needed
            current_hash = get_file_hash(json_file)
            last_hash = state.get(rel_path)

            if args.force or last_hash != current_hash:
                convert_json_to_hcl(json_file, file_type, build_platform=build_platform, backup=args.backup)
                state[rel_path] = current_hash
            else:
                logging.debug(f"  ↳ Skipping unchanged: {json_file.name}")

    save_state(state)
    logging.info("All template configurations processed successfully.")


if __name__ == "__main__":
    main()

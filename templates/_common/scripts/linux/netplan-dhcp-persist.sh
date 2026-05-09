#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up stable DHCP netplan configuration (MAC-based identifier)"

# =============================================================================
# 1. Dynamically detect the primary network interface
# =============================================================================
# Prefer the interface that has the default route (most reliable)
PRIMARY_IFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}' 2>/dev/null || true)

if [[ -z "$PRIMARY_IFACE" ]]; then
    # Fallback: find the first UP ethernet interface
    PRIMARY_IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^(ens|eno|enp|eth)/ && $3 ~ /UP/ {print $2; exit}')
fi

if [[ -z "$PRIMARY_IFACE" ]]; then
    echo "ERROR: Could not detect primary network interface"
    exit 1
fi

echo "Detected primary interface: ${PRIMARY_IFACE}"

# =============================================================================
# 2. Get MAC address of the interface
# =============================================================================
MAC_ADDRESS=$(ip link show "${PRIMARY_IFACE}" | awk '/link\/ether/ {print $2}')
if [[ -z "$MAC_ADDRESS" ]]; then
    echo "ERROR: Could not determine MAC address for ${PRIMARY_IFACE}"
    exit 1
fi

echo "MAC Address: ${MAC_ADDRESS}"

# =============================================================================
# 3. Create high-priority netplan config (01-*.yaml)
# =============================================================================
CONFIG_FILE="/etc/netplan/01-${PRIMARY_IFACE}.yaml"

cat > "${CONFIG_FILE}" <<EOF
# Ansible/Packer managed - Stable DHCP using MAC identifier
network:
  version: 2
  renderer: networkd
  ethernets:
    ${PRIMARY_IFACE}:
      match:
        macaddress: ${MAC_ADDRESS}
      set-name: ${PRIMARY_IFACE}
      dhcp4: true
      dhcp6: false
      dhcp-identifier: mac
      dhcp4-overrides:
        use-dns: true
        use-ntp: true
        send-hostname: true
      # Optional: Increase link detection timeout
      link-local: []
EOF

chmod 600 "${CONFIG_FILE}"

echo "==> ${CONFIG_FILE} content:"
cat "${CONFIG_FILE}"

# Remove any conflicting cloud-init files
rm -f /etc/netplan/50-cloud-init.yaml
rm -f /etc/netplan/*cloud-init*.yaml

echo "==> Generated stable netplan config: ${CONFIG_FILE}"

# Apply configuration
echo "==> Applying netplan..."
netplan generate
netplan apply

echo "==> Stable DHCP configuration completed successfully"
ip addr show "${PRIMARY_IFACE}" | head -n 12

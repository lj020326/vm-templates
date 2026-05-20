#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Usage: ./netplan-dhcp-persist.sh [DESIRED_INTERFACE_NAME]
# Example: ./netplan-dhcp-persist.sh ens160
# =============================================================================

DESIRED_IFACE="${1:-ens160}"   # Default to ens160 if no argument provided

echo "======================================================================"
echo "==> Setting up stable DHCP netplan configuration (MAC-based identifier)"
echo "    Desired interface : ${DESIRED_IFACE}"
echo "======================================================================"

# =============================================================================
# 1. Detect current primary interface
# =============================================================================
PRIMARY_IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}' || true)

if [[ -z "$PRIMARY_IFACE" ]]; then
    # Fallback: find the first UP ethernet interface
    PRIMARY_IFACE=$(ip -o link show | awk -F': ' '$2 ~ /^(ens|eno|enp|eth)/ && $3 ~ /UP/ {print $2; exit}')
fi

if [[ -z "$PRIMARY_IFACE" ]]; then
    echo "ERROR: Could not detect primary network interface"
    exit 1
fi

echo "Detected runtime interface : ${PRIMARY_IFACE}"
echo "Desired interface name    : ${DESIRED_IFACE}"

# =============================================================================
# 2. Get MAC and Current IP (before changes)
# =============================================================================
MAC_ADDRESS=$(ip link show "${PRIMARY_IFACE}" | awk '/link\/ether/ {print $2}')
CURRENT_IP=$(ip addr show "${PRIMARY_IFACE}" | awk '/inet / {print $2; exit}' | cut -d'/' -f1 || echo "N/A")

echo "MAC Address               : ${MAC_ADDRESS}"
echo "Current IP Address        : ${CURRENT_IP}"
echo "======================================================================"

if [[ -z "$MAC_ADDRESS" ]]; then
    echo "ERROR: Could not determine MAC address for ${PRIMARY_IFACE}"
    exit 1
fi

# =============================================================================
# 3. Create high-priority netplan config
# =============================================================================
CONFIG_FILE="/etc/netplan/01-${DESIRED_IFACE}.yaml"

cat > "${CONFIG_FILE}" <<EOF
# Packer managed - Stable DHCP using MAC identifier
network:
  version: 2
  renderer: networkd
  ethernets:
    ${PRIMARY_IFACE}:
      match:
        macaddress: ${MAC_ADDRESS}
EOF

# Only add set-name if the runtime interface differs from desired name
if [[ "${PRIMARY_IFACE}" != "${DESIRED_IFACE}" ]]; then
    echo "      set-name: ${DESIRED_IFACE}" >> "${CONFIG_FILE}"
    echo "    (set-name added because runtime interface differs from desired)"
else
    echo "    (set-name skipped - interface name already matches desired)"
fi

cat >> "${CONFIG_FILE}" <<EOF
      dhcp4: true
      dhcp6: false
      dhcp-identifier: mac
      dhcp4-overrides:
        use-dns: true
        use-ntp: true
        send-hostname: true
      link-local: []
EOF

chmod 600 "${CONFIG_FILE}"

echo "==> Generated ${CONFIG_FILE}:"
cat "${CONFIG_FILE}"
echo "----------------------------------------------------------------------"

# Remove conflicting cloud-init files
echo "==> Removing conflicting cloud-init netplan files..."
rm -f /etc/netplan/50-cloud-init.yaml
rm -f /etc/netplan/*cloud-init*.yaml

## Do not apply since the packer shell provisioner is expecting the IP to remain the same
## =============================================================================
## 4. Apply configuration
## =============================================================================
#echo "==> Applying netplan..."
#netplan generate
#netplan apply
#
#echo "==> Stable DHCP configuration completed successfully"
#echo "Final interface status:"
##ip addr show "${DESIRED_IFACE}" 2>/dev/null | grep -E "inet |link/ether" || \
##ip addr show "${PRIMARY_IFACE}" | grep -E "inet |link/ether"
#ip addr show "${DESIRED_IFACE}" | head -n 12 || \
#ip addr show "${PRIMARY_IFACE}" | head -n 12

echo "=== Netplan persistent config written successfully ==="
echo "   The new configuration will be applied on the next reboot."
echo "======================================================================"

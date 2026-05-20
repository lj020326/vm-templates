#!/usr/bin/env bash

set -e
set -x

# =============================================================================
# Detect OS Family
# =============================================================================
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_ID=${ID,,}
    OS_FAMILY=""
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
        OS_FAMILY="debian"
    elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "fedora" || "$OS_ID" == "ol" || "$ID_LIKE" == *"rhel"* ]]; then
        OS_FAMILY="redhat"
    fi
else
    echo "WARNING: Could not detect OS via /etc/os-release"
fi

echo "==> Detected OS Family: ${OS_FAMILY:-unknown}"

# =============================================================================
# NETWORK / CLOUD-INIT CLEANUP
# =============================================================================
echo "==> Cleaning up networking artifacts..."

# Debian/Ubuntu - Netplan cleanup
if [[ "$OS_FAMILY" == "debian" ]]; then
    echo "==> Debian/Ubuntu: Cleaning netplan configs..."

    # Remove cloud-init generated files
    sudo rm -f /etc/netplan/50-cloud-init.yaml
    sudo rm -f /etc/netplan/*cloud-init*.yaml

    # Keep only our high-priority stable config, remove others
    sudo find /etc/netplan -name "*.yaml" ! -name "01-*" -delete 2>/dev/null || true

    # Re-apply netplan if any config exists
    if sudo ls /etc/netplan/*.yaml >/dev/null 2>&1; then
        sudo netplan generate 2>/dev/null || true
        sudo netplan apply 2>/dev/null || true
    fi
fi

# RedHat family - Basic NetworkManager cleanup
if [[ "$OS_FAMILY" == "redhat" ]]; then
    echo "==> RedHat family: Cleaning NetworkManager/DHCP caches..."
#    sudo rm -f /etc/sysconfig/network-scripts/ifcfg-* 2>/dev/null || true
    sudo rm -f /var/lib/NetworkManager/*dhcp* /var/lib/dhclient/* 2>/dev/null || true
    sudo systemctl restart NetworkManager 2>/dev/null || true
fi

# Common cleanup for all distros
sudo rm -f /var/lib/dhcp/* 2>/dev/null || true

# cloud-init cleanup (works on both families)
if command -v cloud-init >/dev/null 2>&1; then
    echo "==> Running cloud-init clean..."
    sudo cloud-init clean --logs --machine-id 2>/dev/null || true
    sudo rm -rf /var/lib/cloud/instances/* /var/lib/cloud/instance 2>/dev/null || true
fi

echo "==> Network cleanup completed."

# =============================================================================
# SSH Host Keys
# =============================================================================
echo "==> Cleaning up SSH host keys..."
sudo rm -f /etc/ssh/ssh_host_*

# =============================================================================
# OS-specific package cleanup
# =============================================================================
if [[ "$OS_FAMILY" == "debian" ]]; then
    sudo apt-get clean
elif [[ "$OS_FAMILY" == "redhat" ]]; then
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        sudo yum clean all
        sudo rm -rf /var/cache/yum
    fi
fi

# =============================================================================
# General system cleanup
# =============================================================================
sudo rm -rf /tmp/* /var/tmp/*
sudo rm -f /var/log/audit/audit.log /var/log/wtmp /var/log/lastlog 2>/dev/null || true

# Remove old udev rules
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# Reset hostname
sudo bash -c "cat /dev/null > /etc/hostname"

# =============================================================================
# Machine-ID fix (critical for templates)
# =============================================================================
if [ -f /etc/machine-id ]; then
    echo "==> Resetting machine-id..."
    sudo truncate -s 0 /etc/machine-id
    echo -n | sudo tee /etc/machine-id > /dev/null
fi

if [ -f /var/lib/dbus/machine-id ]; then
    sudo rm -f /var/lib/dbus/machine-id
    sudo ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true
fi

# Cleanup shell history
history -w
history -c

echo "==> Full cleanup completed successfully"

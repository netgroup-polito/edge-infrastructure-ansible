#!/bin/bash

cat << "EOF"
  _____    _             _____ _                               
 | ____|__| | __ _  ___ / ____| | ___  __ _ _ __  _   _ _ __   
 |  _| / _` |/ _` |/ _ \ |    | |/ _ \/ _` | '_ \| | | | '_ \  
 | |__| (_| | (_| |  __/ |____| |  __/ (_| | | | | |_| | |_) | 
 |_____\__,_|\__, |\___|\_____|_|\___|\__,_|_| |_|\__,_| .__/  
             |___/                                      |_|     
EOF

echo "This script will remove all components installed by the edge-infrastructure-ansible project."
echo "Please make sure to backup any important data before proceeding."
echo "You will be prompted for confirmation before any destructive actions."
echo

# Check if script is running with sudo
if [ "$EUID" -ne 0 ]; then
  echo "This script needs sudo privileges, please run: sudo ./$(basename $0)"
  exit 1
fi

# Ask for confirmation
read -p "Are you sure you want to proceed with the cleanup? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Cleanup aborted."
  exit 0
fi

echo "Starting cleanup process..."
echo "--------------------------"

# Step 1: Uninstall K3s
echo "[1/12] Uninstalling K3s..."
if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
  /usr/local/bin/k3s-uninstall.sh
  echo "✓ K3s uninstalled successfully."
else
  echo "K3s uninstall script not found, skipping."
fi

# Step 2: Remove K3s data directories
echo "[2/12] Removing K3s data directories..."
rm -rf /etc/rancher/k3s /var/lib/rancher/k3s
echo "✓ K3s data directories removed."

# Step 3: Remove Helm
echo "[3/12] Removing Helm..."
rm -rf /usr/local/bin/helm ~/.helm ~/.config/helm
echo "✓ Helm removed."

# Step 4: Remove virtctl (KubeVirt CLI)
echo "[4/12] Removing virtctl (KubeVirt CLI)..."
rm -f /usr/local/bin/virtctl
echo "✓ virtctl removed."

# Step 5: Remove kubectl configuration
echo "[5/12] Removing kubectl configuration..."
rm -rf ~/.kube
echo "✓ kubectl configuration removed."

# Step 6: Remove Ansible repository
echo "[6/12] Removing Ansible repository..."
rm -f /etc/apt/sources.list.d/ansible-*.list
echo "✓ Ansible repository removed."

# Step 7: Remove Helm repository
echo "[7/12] Removing Helm repository..."
rm -f /etc/apt/sources.list.d/helm-*.list
echo "✓ Helm repository removed."

# Step 8: Remove management user
echo "[8/12] Checking for management user..."
if id "mgmt" &>/dev/null; then
  read -p "Do you want to remove the 'mgmt' user? (y/n): " remove_user
  if [[ "$remove_user" =~ ^[Yy]$ ]]; then
    userdel -r mgmt
    echo "✓ Management user removed."
  else
    echo "Skipping management user removal."
  fi
else
  echo "Management user not found, skipping."
fi

# Step 9: Remove temporary files
echo "[9/12] Removing temporary files..."
rm -rf /home/mgmt/edge-infrastructure-ansible-main/
echo "✓ Temporary files removed."

# Step 10: Optional: Uninstall system packages
echo "[10/12] Checking for system packages..."
read -p "Do you want to remove installed system packages (ansible, python3-kubernetes, kubectl, helm)? (y/n): " remove_packages
if [[ "$remove_packages" =~ ^[Yy]$ ]]; then
  apt remove -y ansible python3-kubernetes kubectl helm
  echo "✓ System packages removed."
else
  echo "Skipping system packages removal."
fi

# Step 11: Clean orphaned package dependencies
echo "[11/12] Cleaning orphaned package dependencies..."
apt autoremove -y
echo "✓ Orphaned package dependencies cleaned."

# Step 12: Reset IP tables rules
echo "[12/12] Resetting IP tables rules..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
echo "✓ IP tables rules reset."

echo
echo "Cleanup completed successfully!"
echo "Your system has been restored to a state close to before the edge-infrastructure-ansible installation."
echo "You may need to reboot your system for all changes to take effect."
echo 
#!/bin/bash

cat << "EOF"
    __ ____________    ____           __        ____      __  _
   / //_/__  / ___/   /  _/___  _____/ /_____ _/ / /___ _/ /_(_)___  ____
  / ,<   /_ <\__ \    / // __ \/ ___/ __/ __ `/ / / __ `/ __/ / __ \/ __ \
 / /| |___/ /__/ /  _/ // / / (__  ) /_/ /_/ / / / /_/ / /_/ / /_/ / / / /
/_/ |_/____/____/  /___/_/ /_/____/\__/\__,_/_/_/\__,_/\__/_/\____/_/ /_/

EOF

#######################################
#   STEP 0: CHECK SUDO PRIVILEGES     #
#######################################

if [ "$EUID" -ne 0 ]
  then echo "This script need sudo privileges, please run: sudo ./$(basename $0)"
  exit
fi

if [[ $# -eq 3 ]]; then
  echo "Installation with Liqo peering started."
elif [[ $# -eq 0 ]]; then
  echo "Installation without Liqo peering started.
  Liqo will be installed just locally."
else
  echo "Usage:
  Installation with liqo peering:
  sudo ./$(basename $0) <remote_target_ip> <remote_target_user> <remote_target_password>
  Or without parameter for no Liqo peering."
  exit 1
fi

echo "K3S cluster setup started"
echo ""

#################################################
#   STEP 1: MANAGEMENT USER CREATION            #
#################################################

# Create mgmt user
echo -n "Management user creation..."

adduser --gecos "Management user" --disabled-password mgmt >/dev/null
echo "mgmt:root" | sudo chpasswd >/dev/null
usermod -aG sudo mgmt

if [ $? -eq 0 ]; then
  echo " OK "
else
  echo "KO, exiting"
  exit 1
fi
echo ""

################################
#   STEP 2: Install Ansible    #
################################
echo "Installing Ansible..."
# Install Ansible

apt update 2>/dev/null
apt upgrade -y 2>/dev/null
apt install -y ansible 2>/dev/null
apt install -y sshpass 2>/dev/null
apt install -y unzip 2>/dev/null

#######################################
#   STEP 2.1: Check Ansible version   #
#######################################
ansible --version | grep -q 2.10

#By default seems that apt install ansible on ubuntu server "ubuntu-22.04.4-live-server-arm64" install ansible 2.10
#which is not appropriate to run the k3s_installation playbook

#Install latest ansible version
#with ansible 2.10 the k3s-installation playbook fail
if [ $? -eq 0 ]; then
  echo "Upgrading ansible version..."
  apt remove -y ansible
  apt --purge autoremove -y
  apt -y install software-properties-common
  apt-add-repository -y ppa:ansible/ansible
  apt install -y ansible
fi

#########################################
#   STEP 3: Download ansible script     #
#########################################
echo -n "Downloading Ansible script.."
cd /home/mgmt/

curl -LO https://github.com/netgroup-polito/edge-infrastructure-ansible/archive/refs/heads/main.zip

#Check repo installation outcome
if [ $? -eq 0 ]; then
  echo -e " OK "
else
  echo "KO, exiting"
  exit 1
fi

unzip main.zip
rm main.zip

#############################################
#   STEP 4: Substitute remote target ip     #
#############################################


# If three arguments are provided, the script will assume that the user wants to set up peering with a remote cluster.
# In this case, it will install Liqo locally and then configure peering with the remote cluster using the provided IP address, username, and password.

# If no arguments are provided, the script will assume that the user wants to install Liqo locally, without peering.
# The second option could be useful for master node initialization.
if [ $# -eq 3 ]; then
  sed -i "s/<remote_target_ip>/$1/g" /home/mgmt/edge-infrastructure-ansible-main/inventory
  sed -i "s/<remote_target_user>/$2/g" /home/mgmt/edge-infrastructure-ansible-main/inventory
  sed -i "s/<remote_target_password>/$3/g" /home/mgmt/edge-infrastructure-ansible-main/inventory
  sed -i "s/<remote_target_ip>/$1/g" /home/mgmt/edge-infrastructure-ansible-main/playbook/roles/liqo-get-kubeconfig-remote/vars/main.yaml
  sed -i "s/<remote_target_user>/$2/g" /home/mgmt/edge-infrastructure-ansible-main/playbook/roles/liqo-get-kubeconfig-remote/tasks/main.yaml
else
  sed -i "s/^.*<remote_target_ip>/#&/g" /home/mgmt/edge-infrastructure-ansible-main/inventory
fi


######################################
#   STEP 5: Start ansible script     #
######################################
echo "Running Ansible script.."

#This line is used to avoid to insert the mgmt sudo password to run the ansible script
echo "mgmt ALL=(ALL) NOPASSWD:ALL" | EDITOR='tee -a' visudo

runuser -l mgmt -c 'ansible-galaxy collection install -r /home/mgmt/edge-infrastructure-ansible-main/requirements.yml'
runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/env_setup.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'
runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/dashboard_deploy.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'

if [ $# -eq 3 ]; then
  runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/liqo_incoming_peering.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'
  runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/liqo_outgoing_peering.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'
fi

######################################
#          STEP 6: Clean             #
######################################
while true; do
  echo "Do you want to delete the ansible script located in /home/mgmt/edge-infrastructure-ansible-main? (y/n)"
  read answer
  case $answer in
    [Yy])
      rm -rf /home/mgmt/edge-infrastructure-ansible-main
      echo "/home/mgmt/edge-infrastructure-ansible-main deleted."
      break
      ;;
    [Nn])
      echo "/home/mgmt/edge-infrastructure-ansible-main will be kept"
      break
      ;;
    *)
      echo "Please provide a valid answer (y/n)"
      ;;
  esac
done

################################################
#          STEP 7: Password change             #
################################################
function check_passwords() {
  if [ $1 != $2 ]; then
    echo "Sorry, passwords do not match. Try again"
    return 1
  fi
}

while true; do
  echo "The user mgmt was been created and used to perform the installation.
  The default password is: root
  Would you like to change the password? (y/n)"
  read answer
  case $answer in
    [Yy])
      CHECK_OK=0
      while true; do
        read -p "New password: " -s pw1
        echo
        read -p "Retype new password: " -s pw2
        echo

        check_passwords "$pw1" "$pw2"
        if [ $? -eq 0 ]; then
          CHECK_OK=1
          break
        fi
      done
      if [ $CHECK_OK -eq 1 ]; then
        echo "Password changed successfully."
        break
      fi
      ;;
    [Nn])
      break
      ;;
    *)
      echo "Please provide a valid answer (y/n)"
      ;;
  esac
done

echo "Installation completed."
exit 0

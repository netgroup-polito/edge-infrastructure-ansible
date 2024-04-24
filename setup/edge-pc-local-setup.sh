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
apt install sshpass 2>/dev/null
apt install unzip 2>/dev/null

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
unzip main.zip
rm main.zip

#####################################
#   DEBUG: For debugging purpose    #
#   You can set your repository     #
#     and your branch to test       #
#####################################
#git clone https://github.com/giovannimirarchi420/edge-infrastructure-ansible.git /home/mgmt/edge-infrastructure-ansible
#cd /home/mgmt/edge-infrastructure-ansible
#git remote update
#git fetch
#git checkout --track origin/feature/setup-script

#Check repo installation outcome
if [ $? -eq 0 ]; then
  echo -e " OK "
else
  echo "KO, exiting"
  exit 1
fi

######################################
#   STEP 4: Start ansible script     #
######################################
echo "Running Ansible script.."
#This line is used to avoid to insert the mgmt sudo password to run the ansible script
echo "mgmt ALL=(ALL) NOPASSWD:ALL" | EDITOR='tee -a' visudo

runuser -l mgmt -c 'ansible-galaxy collection install -r /home/mgmt/edge-infrastructure-ansible-main/requirements.yml'
runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/env_setup.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory.local'

######################################
#          STEP 5: Clean             #
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

echo "Installation completed."
exit 0

#!/bin/bash

cat << "EOF"
    __ ____________    ____           __        ____      __  _
   / //_/__  / ___/   /  _/___  _____/ /_____ _/ / /___ _/ /_(_)___  ____
  / ,<   /_ <\__ \    / // __ \/ ___/ __/ __ `/ / / __ `/ __/ / __ \/ __ \
 / /| |___/ /__/ /  _/ // / / (__  ) /_/ /_/ / / / /_/ / /_/ / /_/ / / / /
/_/ |_/____/____/  /___/_/ /_/____/\__/\__,_/_/_/\__,_/\__/_/\____/_/ /_/

EOF

#######################################
#    UTILITY FUNCTIONS DEFINITION     #
#######################################

function match_string() {
  if [ "$1" != "$2" ]; then
    echo "Sorry, passwords do not match. Try again"
    return 1
  fi
}

function check_passwords() {
  while true; do
    read -p "$1" answer
    case $answer in
      [Yy])
        CHECK_OK=0
        while true; do
          read -rep "New password: " -s pw1

          read -rep "Retype new password: " -s pw2

          match_string "$pw1" "$pw2"
          if [ $? -eq 0 ]; then
            CHECK_OK=1
            if [ "$2" == "grafana" ]; then
              GRAFANA_PSW="$pw1"
            else
              PSW_MGMT="$pw1"
            fi
            break
          fi
        done
        if [ $CHECK_OK -eq 1 ]; then
          echo "Password changed successfully"
          return 0
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

}


####################################################
#                                                  #
# These variables and functions are used to        #
# construct a summary table at the end of          #
# the script execution.                            #
#                                                  #
####################################################
column_len=( 13 40 20 )
table_vertical_separator="|"
table_horizontal_separator="-"
table_border_mark="+"


write_separate_line() {
        for n in "${column_len[@]}"
        do
        echo -n $table_border_mark
        for i in $(seq 1 $n); do echo -n $table_horizontal_separator; done
        done
        echo -n $table_border_mark
        echo ""
}

write_row() {
        printed=""
        recurse=""
        remaining_cols=()
        ci=0
        echo -n $table_vertical_separator
        while (( "$#" )); do
                value=$1
                remaining=${column_len[ci]}
                size=${#value}
                substr=""
                if [ "$size" -gt "$remaining" ]; then
                    let "start=remaining+1"
                    substr=$(echo "$value" | cut -c$start-$size)
                    value=$(echo "$value" | cut -c1-$remaining)
                    recurse="yes"
                fi
                remaining_cols+=($substr)
                echo -n $value
                let "remaining-=size"
                for i in $(seq 1 $remaining); do echo -n " "; done
                echo -n $table_vertical_separator
                let "ci+=1"
                shift
        done

        while [ $ci -lt "${#column_len[@]}" ]
        do
            remaining=${column_len[ci]}
            for i in $(seq 1 $remaining); do echo -n " "; done
            echo -n $table_vertical_separator
            let "ci+=1"
        done

        echo ""
        if [ ! -z "$recurse" ]
        then
        write_row "${remaining_cols[@]}"
        fi

}

print_end_message() {
        write_separate_line
        write_row "Dashboard" "URL" "Password"
        write_separate_line
        write_row "General" "http://$1/default" "Not required"
        write_separate_line
        write_row "K3S" "http://$1/k3sdashboard" "Check README.md"
        write_separate_line
        write_row "Grafana" "http://$1/grafana" "$2"
        write_separate_line
        write_row "Prometheus" "http://$1/prometheus/graph" "Not required"
        write_separate_line
        write_row "KubeVirt" "http://kubevirt.local" "Not required"
        write_separate_line
}


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
  Or no parameters to install Liqo without peerings, which have to be set up manually later."
  exit 1
fi

echo "K3S cluster setup started"
echo ""

#################################################
#   STEP 1: MANAGEMENT USER CREATION            #
#################################################

echo "Getting OS version..."
. /etc/os-release

if [ ! "$ID" == "ubuntu" ]; then
    echo ""
    echo "$PRETTY_NAME is not supported by this script"
    echo
    exit 1
fi

GRAFANA_PSW_ASK_STRING="Would you like to change the Grafana password for 'admin' user?
Pressing 'n' will set the password to the default 'root' (y/n): "
GRAFANA_PSW="root"
check_passwords "$GRAFANA_PSW_ASK_STRING" "grafana"

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

#################################################
##   STEP 3: Install Ansible + required tools   #
#################################################

# --------------------------------------------
# Check to see if Ansible is already installed
# --------------------------------------------
echo ""
echo "Checking to see if Ansible is already installed"
if hash ansible 2>/dev/null ; then
  echo ""
  echo "Ansible is already installed"
  echo ""
else
  # ---------------
  # Install Ansible + tools
  # ---------------

  echo ""
  echo "Installing sshpass, unzip and curl"
  apt install -y sshpass
  apt install -y unzip
  apt install -y curl
  echo ""
  echo "Adding PPA, then installing Ansible"
  apt-add-repository ppa:ansible/ansible -y
  apt-get update
  apt-get install software-properties-common ansible python3-apt -y

fi

#########################################
#   STEP 3: Download ansible script     #
#########################################
echo -n "Downloading Ansible script.."
cd /home/mgmt/
#for testing
#curl -LO https://github.com/netgroup-polito/edge-infrastructure-ansible/archive/refs/heads/main.zip
curl -LO https://github.com/Aleint/edge-infrastructure-ansible/archive/refs/heads/test.zip

#Check repo installation outcome
if [ $? -eq 0 ]; then
  echo -e " OK "
else
  echo "KO, exiting"
  exit 1
fi
#for testing
unzip test.zip
mv edge-infrastructure-ansible-test edge-infrastructure-ansible-main
rm test.zip
#unzip main.zip
#rm main.zip

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
  sed -i "s/<grafana_password>/$GRAFANA_PSW/g" /home/mgmt/edge-infrastructure-ansible-main/playbook/roles/energymon/files/values.yaml
else
  sed -i "s/^.*<remote_target_ip>/#&/g" /home/mgmt/edge-infrastructure-ansible-main/inventory
  sed -i "s/<grafana_password>/$GRAFANA_PSW/g" /home/mgmt/edge-infrastructure-ansible-main/playbook/roles/energymon/files/values.yaml
fi

###########################################
#          STEP 5: KubeVirt               #
###########################################

read -p "Do you want to install KubeVirt? (y/n) " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    export INSTALL_KUBEVIRT=true
else
    export INSTALL_KUBEVIRT=false
fi


######################################
#   STEP 6: Start ansible script     #
######################################
echo "Running Ansible script.."

#This line is used to avoid to insert the mgmt sudo password to run the ansible script
echo "mgmt ALL=(ALL) NOPASSWD:ALL" | EDITOR='tee -a' visudo

runuser -l mgmt -c 'ansible-galaxy collection install -r /home/mgmt/edge-infrastructure-ansible-main/requirements.yml'
runuser -l mgmt -c "ansible-playbook \
  /home/mgmt/edge-infrastructure-ansible-main/playbook/env_setup.yaml \
  -e install_kubevirt=$INSTALL_KUBEVIRT \
  -i /home/mgmt/edge-infrastructure-ansible-main/inventory"
runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/dashboard_deploy.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'

if [ $# -eq 3 ]; then
  runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/liqo_incoming_peering.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'
  runuser -l mgmt -c 'ansible-playbook /home/mgmt/edge-infrastructure-ansible-main/playbook/liqo_outgoing_peering.yaml -i /home/mgmt/edge-infrastructure-ansible-main/inventory'
fi



######################################
#          STEP 7: Clean             #
######################################
while true; do
  read -p "Do you want to delete the ansible script located in /home/mgmt/edge-infrastructure-ansible-main? (y/n) " answer
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
#          STEP 8: Password change             #
################################################
MGMT_USER_PSW_ASK_STRING="The user 'mgmt' has been created and used for the installation.
The default password is: root
Would you like to change the password? (y/n) "
PSW_MGMT="root"
check_passwords "$MGMT_USER_PSW_ASK_STRING" "mgmt"
echo "mgmt:$PSW_MGMT" | chpasswd

if [ $? -ne 0 ]; then
  echo "There was an error while changing the password. As a result, the default password 'root' will remain in place."
fi
echo ""

# Get local IP address
local_ip=$(hostname -I | awk '{print $1}')
print_end_message "$local_ip" "$GRAFANA_PSW"
echo ""
echo "Installation completed."


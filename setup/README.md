# Installation script for the edge computer

This folder contains a script that installs all the commands and software required for a local computer to join the edge infrastructure defined by the FLUIDOS and LEGGERO projects.
This script must be executed when the computer running at the edge is started from the first time. Additional customization tasks can be carried out later, from a remote administrator, thanks to the management user created in this step.
In the end, this PC will become a mini-K3s cluster, with the possibility to offload jobs in the cloud thanks to Liqo.

The script will perform the following tasks:
1. Create a management user (mgmt)
2. Install Ansible
   1. Check if the Ansible is 2.10, if so, install the latest version
3. Download Ansible GIT repository files
4. Start Ansible script

## How to run

This script need sudo privileges to be run.

Add execution permission:
``` chmod +x edge-pc-local-setup.sh ```

If three arguments are provided, the script will assume that the user wants to set up peering with a remote cluster.
In this case, it will install Liqo locally and then configure peering with the remote cluster using the provided IP address, username, and password.

``` sudo ./edge-pc-local-setup.sh <remote_target_ip> <remote_target_user> <remote_target_password> ```

If no arguments are provided, the script will assume that the user wants to install Liqo locally, without peering.
The second option could be useful for master node initialization.
``` sudo ./edge-pc-local-setup.sh ```

Or with one-command run:

With Liqo peering:
```bash
 curl https://raw.githubusercontent.com/netgroup-polito/edge-infrastructure-ansible/main/setup/edge-pc-local-setup.sh
 chmod +x edge-pc-local-setup.sh
 ./edge-pc-local-setup.sh <remote_target_ip> <remote_target_user> <remote_target_password>
``` 


Without Liqo peering:
```bash
 curl https://raw.githubusercontent.com/netgroup-polito/edge-infrastructure-ansible/main/setup/edge-pc-local-setup.sh
 chmod +x edge-pc-local-setup.sh
 ./edge-pc-local-setup.sh
``` 

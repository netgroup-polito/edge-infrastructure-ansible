# Installation script for the edge computer

This folder contains a script that installs all the commands and software required for a local computer to join the edge infrastructure defined by the FLUIDOS and LEGGERO projects.
This script must be executed when the computer running at the edge is started from the first time. Additional customization tasks can be carried out later, from a remote administrator, thanks to the management user created in this step.
In the end, this PC will become a mini-K3s cluster, with the possibility to offload jobs in the cloud thanks to Liqo.

The script will perform the following tasks:
1. Create a management user (mgmt)
2. Install sshpass, curl and unzip
3. Install Ansible
4. Download and unzip Ansible script from github repository
5. Start Ansible script
# Installation script

This folder contains a script that is useful for the installation of the k3s cluster locally with just one command.

The script will perform the following tasks:
1. Create a management user (mgmt)
2. Install Ansible
   1. Check if the Ansible is 2.10, if so, install the latest version
3. Clone Ansible GIT repository
4. Start Ansible script

## How to run

This script need sudo privileges to be run.

Add execution permission:
``` chmod +x setup.sh ```

Run:
``` sudo ./setup.sh ```

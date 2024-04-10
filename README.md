# Edge Infrastructure Ansible

This repository contains the Ansible playbooks and roles to deploy the edge infrastructure on the mini-pc and the edge server.

## Requirements

- The operative system of the VMs created in the mini-pc was Ubuntu 22.04, we do not guarantee the correct execution of the playbooks on other operative systems.



## NOTICE: 
**The users used in the two machine should have root privileges in order to work properly**

## Verify your Inventory

```bash
ansible-inventory -i inventory --list
```

## Ping the myhosts group in your inventory

```bash
ansible myhosts -m ping -i inventory
```

## DDNS Setup

```bash
ansible-playbook playbook/ddns-setup.yaml -i inventory.ini
```

## Setup the environment and deploy the dashboard

```bash
ansible-playbook --ask-become-pass playbook/env-setup.yaml.yaml -i inventory
```

```bash
ansible-playbook --ask-become-pass playbook/dashboard_deploy.yaml -i inventory
```

Per recuperare il token per la dashboard dal mini-pc:

```bash
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

## Liqo Peering

```bash
ansible-playbook playbook/liqo-peering.yaml -i inventory
```

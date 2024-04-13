# Edge Infrastructure Ansible

This repository contains the Ansible playbooks and roles to deploy the edge infrastructure on the mini-pc and the edge server.

## Requirements

- Ansible collections:
    - community.kubernetes 

It can be installed using the following command:

```bash
ansible-galaxy collection install community.kubernetes
```


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
ansible-playbook playbook/env_setup.yaml -i inventory
```

```bash
ansible-playbook playbook/dashboard_deploy.yaml -i inventory
```

Per recuperare il token per la dashboard dal mini-pc:

```bash
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

## Liqo Peering

```bash
ansible-playbook playbook/liqo-peering.yaml -i inventory
```

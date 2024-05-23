# Setting up and edge-to-cloud infrastructure with Ansible

This software repository contains some scripts to setup an edge-to-cloud infrastructure, which is made by:
- a variable number of **edge nodes**, equipped with a lightweight flavor of Kubernetes (K3s)
- a **'cloud' Kubernetes cluster** (e.g., running on a public cloud or on premises)

The installed software includes Liqo, which enables the creation of _'stretched Kubernetes clusters'_, which can span across edge devices and cloud. This allows (a) edge users to transparently offload local applications on the cloud cluster, and (b) the cloud manager to offload (i.e., _push_) applications on edge node, achieving a transparent _cloud continuum_.

Installation scripts can operate in two ways:
- **Automatic install**: a `bash` script is executed directly on the edge node, which installs all the required software and (optionally) sets up a Liqo peering with the cloud cluster.
- **Manual install**: multiple Ansible scripts can be executed individually, allowing to install and customize all the required software on the edge node, with more possibilities to customize running parameters and/or to decide which software has to be installed. Furthermore, these scripts can be launched from an Ansible control server, and executed on one or more edge nodes contemporarily (_push_ mode).

This project is still in its experimental phase; testing has been done mainly in Ubuntu 22.04 LTS.

## Requirements and suggestions
- OS language on edge node must be English.
- It is recommended to disable swap and firewall on the managed node.
- If the firewall is enabled, the  ```prereq``` role in the fist Ansible playbook is responsible to set the right environment as explained in [K3s requirements](https://docs.k3s.io/installation/requirements).

**Note 1**: the port 22/tcp is used by Ansible, so make sure you have a rule for that if the firewall is enabled. 
**Note 2**: if Ansible playbooks are executed directly instead of the automatic `bash` script, the node that starts the playbook must have **Ansible** installed.


## Automatic installation (using setup script)

The automatic install consists in a setup script that has to be launched on each edge node.

Before proceeding with the installation, please run an ```apt update``` and ``` apt upgrade ```.

Then, we have to download the install script from this repository and update its permissions:

```bash
 curl https://raw.githubusercontent.com/netgroup-polito/edge-infrastructure-ansible/main/setup/edge-pc-local-setup.sh
 chmod +x edge-pc-local-setup.sh
``` 

The script can be executed either with three arguments, or with nothing.
In the first case, the script will assume that the user would like to install all the required software _and_ to set up a Liqo peering with a remote cluster, using the provided IP address, username, and password:

```bash
 sudo ./edge-pc-local-setup.sh <remote_target_ip> <remote_target_user> <remote_target_password>
``` 

If no arguments are provided, the script will assume that the user wants to install all the required software (including Liqo on the local machine), without setting up the peering with a remote cluster.
The second option could be useful for master node initialization, or if the user needs to peer to a remote cluster at a later time: 

```bash
 sudo ./edge-pc-local-setup.sh
``` 

## Manual installation (using individual ansible files, for expert users)

Manual install is based on multiple Ansible files, which need to be launched individually.
This provides more flexibility in the installation process, e.g., by enabling to customize some parameters (e.g., you can install a software locally or on a remote machine), and by selecting exactly which software has to be installed.
However, this method is discouraged for normal users, which are invited to use the installation script.

There are few files to fill with the real values: ``` inventory ```, ```playbook/roles/liqo-get-kubeconfig-remote/vars/main.yaml ``` and ```playbook/roles/ddns/vars/main.yaml ``` 

Then launch all playbooks one by one:
```bash 
ansible-playbook playbook/env_setup.yaml -i inventory 
```
The ```env_setup.yaml``` playbook checks prerequisites, installs tools, sets up a k3s cluster, deploys operators (Nginx, Liqo and monitoring), and configures DDNS. Check the [Environment Setup](#environment-setup) section for further details.


```bash 
ansible-playbook playbook/dashboard_deploy.yaml -i inventory 
```
The ```dashboard_deploy.yaml``` playbook installs the k3s and Liqo dashboards. Run this playbook after completing the ```env_setup.yaml``` playbook. Access the dashboards at ```http://<local_machine_ip>/```. Check the [Dashboard](#dashboard) section for further details.


```bash 
ansible-playbook playbook/liqo_incoming_peering.yaml -i inventory 
```
```bash 
ansible-playbook playbook/liqo_outgoing_peering.yaml -i inventory 
```
The ```liqo_incoming_peering.yaml```, ```liqo_outgoing_peering.yaml``` playbook configures Liqo peering with a remote central node. Check the [Liqo In-Band peering - Cloud Continuum](#liqo-in-band-peering---cloud-continuum) section for further information.


### Environment Setup

### Modify the inventory file based on your environment setup
To start the playbooks, you need to modify the **inventory** file in order to be consistent with your cluster setup. 
It is also possible to add new ```vars``` in order to enhance your environment. 

This Ansible playbook sets up the environment:
- Installation of K3S and Liqo on the local node
- Installation and setup of the ddns updater on a specific node (ddns). Configuration concerning the DDNS service is required, check the file ```roles/ddns/vars/main.yaml```.

```bash
ansible-playbook playbook/env_setup.yaml -i inventory
```

In this setup, k3s is installed using ```--disable=traefik``` flag in order to remove Traefik from the cluster, because **nginx** Ingress Controller is used. For more details see the [official documentation](https://docs.k3s.io/networking/networking-services).

## Dashboard
An optional playbook is provided to deploy and access Kubernetes Dashboard within the K3s cluster. To use it run the following command:

```bash
ansible-playbook playbook/dashboard_deploy.yaml -i inventory
```

To access the Dashboard a **token** is needed. The ```dashboard``` role handles the creation of a long-lived Bearer Token.
To retrieve the token run the following command:
```bash
sudo kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

The dashboard is reachable via both HTTP and HTTPS at the address __*http(s)://{node IP address}/dashboard*__ thanks to the **LoadBalancer service**.
For instance, if the IP address of your edge node is 192.168.1.2, the dashboard will be reached at https://192.168.1.2/dashboard.

###### This playbook installs also the Liqo Dashboard (to be reviewed)

# Energy monitoring
The ```energymon``` role is responsible for installing and configuring the monitoring part.
This role starts immediately after the creation of the k3s cluster.
In order, it will:

1. Install Prometheus and Grafana (if not already present) and set up an ingress for each. 
1. Install Kepler (with attached Grafana dashboard) (if not already present)

In the absence of an ingress for grafana, it is possible to expose and access grafana via nodeport with the following command:

```sudo kubectl expose service prometheus-grafana --type=NodePort --name=grafana-ext --target-port=3000 -n monitoring```

### Grafana configuration

The Grafana configuration is located in ```playbook/roles/energymon/files/values.yaml``` where the password of the ```admin``` user is set via the ```adminPassword``` attribute.

If the configuration is not modified, it is possible to access grafana with the following credentials:

- user: ```admin```
- password: ```root```

### Tips for Re-Installation

To reinstall a specific component, such as Kepler or Prometheus+Grafana, simply uninstall the corresponding Helm release from the target host using the following command:

```sudo helm --kubeconfig /etc/rancher/k3s/k3s.yaml uninstall <release_name> -n monitoring```

The release name can be found and configured in the config file located at ```playbook/roles/energymon/defaults/main.yaml```.

After successfully uninstalling the release, relaunch the ansible script. The script will detect the missing part and proceed with the installation.

# Liqo In-Band peering - Cloud Continuum

Cloud Continuum is a project aimed at seamlessly connecting home resources with cloud services, creating a unified virtual space for resources and services across domestic servers and cloud providers. This initiative enables fluid resource allocation, enhanced data redundancy, and ease of maintenance and monitoring of applications.

## Project Overview

The project adopts the "cloud continuum" paradigm, similar to that in the FLUIDOS European Project. It leverages technologies like Kubernetes and Liqo to facilitate cloud bursting and data redundancy, making it possible for services and data to be processed and stored either locally or in the cloud based on defined policies.

## Key Features

- **Seamless Resource Scaling:** Automatic scaling between local and cloud resources based on demand.
- **Data Redundancy:** Ensures data safety through local and remote replication.
- **Simplified Management:** A minimal dashboard for easy edge-to-cloud interactions.
- **Flexibility and Control:** Customize where applications run and where data is stored.

## Technologies

- **Docker**
- **Kubernetes** (specifically K3s)
- **Bash**
- Programming in **Go**, **JavaScript**, and frameworks like **React** may be needed for further development.

### Prerequisites

- Basic knowledge of Bash and Ansible scripting is recommended.

### Liqo In-Band Peering

These Ansible playbooks perform the in-band peering between the two clusters (targets).

1. Liqo peering from the local node to the central cluster

```bash
ansible-playbook playbook/liqo_outgoing_peering.yaml -i inventory
```

2. Liqo peering from the central cluster to the local node

```bash
ansible-playbook playbook/liqo_incoming_peering_out.yaml -i inventory
```

## Default page

A **web page** hosting links to all dashboards available in this cluster is reachable via: __*http(s)://{node IP address}*__

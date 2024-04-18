# Cloud Continuum

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

## Getting Started

To get started with the Cloud Continuum project, follow these initial setup steps:

### Prerequisites

- Basic knowledge of Bash and Ansible scripting is recommended.

### Environment Setup

 This Ansible playbook setup the environment:

 • Installation of K3S and Liqo on the local node and remote node (myhosts)

 • Installation and setup of the ddns updater on a specific node (ddns). Configuration concerning the DDNS service is required, check the file roles/ddns/vars/main.yaml.


```bash
ansible-playbook playbook/env-setup.yaml -i inventory
```

### K3s Dashboard Installation

This Ansible playbook installs K3s on the local node and remote node (myhosts).

```bash
ansible-playbook playbook/k3s-dashboard_deploy.yaml -i inventory
```

### Liqo Dashboard Installation

This Ansible playbook installs Liqo Dashboard on the local node.

```bash
ansible-playbook playbook/liqo-dashboard_deploy.yaml -i inventory
```

### Liqo In-Band Peering

These Ansible playbooks perform the in-band peering between the two clusters (myhosts).

1. Liqo peering from the local node to the central cluster

```bash
ansible-playbook playbook/liqo_peering_in.yaml -i inventory
```

2. Liqo peering from the central cluster to the local node

```bash
ansible-playbook playbook/liqo_peering_out.yaml -i inventory
```

## License


## Acknowledgments

- Thanks to the Kubernetes community and the developers of Liqo.

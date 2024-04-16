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
- **Kubernetes** (specifically K3d)
- **Bash**
- Programming in **Go**, **JavaScript**, and frameworks like **React** may be needed for further development.

## Getting Started

To get started with the Cloud Continuum project, follow these initial setup steps:

### Prerequisites

- Docker and Kubernetes must be installed on your system.
- Basic knowledge of Bash and Ansible scripting is recommended.

### Installation Steps

1. **Set up Kubernetes using Liqo:**

    ```yaml
    - name: Download and extract liqoctl
      shell: 'curl --fail -LS "https://github.com/liqotech/liqo/releases/download/v0.10.2/liqoctl-linux-amd64.tar.gz" | tar -xz'

    - name: Install liqoctl
      shell: 'sudo install -o root -g root -m 0755 liqoctl /usr/local/bin/liqoctl'

    - name: Install Liqo       
      shell: 'sudo liqoctl install k3s --kubeconfig=/etc/rancher/k3s/k3s.yaml'
    ```

2. **Configure Liqo Peering:**

    Complete the steps in `liqo-peering.yaml` to set up and configure the peering between your local and remote Kubernetes clusters.

### Configuration

Adjust the configuration settings according to your environment and security policies. Check the provided Ansible playbooks (`liqo-setup`, `liqo-part-1`, and `liqo-part-2`) for more details on configuring your deployment.

## Contributing

Contributions to Cloud Continuum are welcome! Please refer to the `CONTRIBUTING.md` for guidelines on how to contribute to this project.

## License


## Acknowledgments

- Inspired by projects like casaos.io.
- Utilizes technologies developed in the FLUIDOS European Project.
- Thanks to the Kubernetes community and the developers of Liqo.

# Creating Kubernetes cluster using K3s with Ansible

## Requirements
The control node needs **Ansible** to start the playbooks. 

It is reccomended to disable swap and firewall on the managed node. If the firewall is enabled, the  ```prereq``` role is responsible to set the right environment as explained in [K3s requirements](https://docs.k3s.io/installation/requirements).
## Usage 
To start the playbooks, you need to modify the **inventory** file in order to be consistent with your cluster setup. 

Start the creation of Kubernetes cluster using the following command:
```bash
ansible-playbook --ask-become-pass playbook/k3s_installation.yaml -i inventory
```

## Kubernetes Dashboard
An optional playbook is provided to deploy and access Kubernetes Dashboard within the K3s cluster. To use it run the following command:
```bash
ansible-playbook --ask-become-pass playbook/dashboard_deploy.yaml -i inventory   ⁠
```

To access the Dashboard a **token** is needed. The ```dashboard``` role handles the creation of a long-lived Bearer Token.
To retrieve the token run the following command:
```bash
sudo kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

The Dashboard can be reached through a **NodePort service**. The ```dashboard``` role handles the configuration of a NodePort service.
To retrieve the NodePort run the following command:
```bash
sudo kubectl --namespace kubernetes-dashboard get svc kubernetes-dashboard -o=jsonpath="{.spec.ports[0].nodePort}"
```

# Energy monitoring
The ```energymon``` role is responsible for installing and configuring the monitoring part.
This role starts immediately after the creation of the k3s cluster.
In order, it will:

1. Check if curl is installed (and install it if necessary)
1. Install helm (if not present)
1. Install Prometheus and Grafana (if not present)
1. Install Kepler (with attached Grafana dashboard) (if not present)

In the absence of an ingress for grafana, it is possible to expose and access grafana via nodeport with the following command:

```sudo kubectl expose service prometheus-grafana --type=NodePort --name=grafana-ext --target-port=3000 -n monitoring```

### Grafana configuration

The Grafana configuration is located in ```playbook/roles/energymon/files/values.yaml``` where the password of the ```admin``` user is set via the ```adminPassword``` attribute.

If the configuration is not modified, it is possible to access grafana with the following credentials:

- user: ```admin```
- password: ```prom-operator```

### Tips for Re-Installation

To reinstall a specific component, such as Kepler or Prometheus+Grafana, simply uninstall the corresponding Helm release from the target host using the following command:

```sudo helm --kubeconfig /etc/rancher/k3s/k3s.yaml uninstall <release_name> -n monitoring```

The release name can be found and configured in the config file located at ```playbook/roles/energymon/defaults/main.yaml```.

After successfully uninstalling the release, relaunch the ansible script. The script will detect the missing part and proceed with the installation.
#!/bin/bash

# Define variables
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
NAMESPACE="monitoring"
PUSHGATEWAY_MANIFEST="/home/mgmt/edge-infrastructure-ansible-main/setup/pushgateway/pushgateway.yaml"
HELM_RELEASE_NAME="prometheus"
HELM_CHART="prometheus-community/kube-prometheus-stack"
VALUES_FILE="/home/mgmt/edge-infrastructure-ansible-main/setup/pushgateway/values.yaml"

# Step 0: Install yq if not already installed
echo "Checking if yq is installed..."
if ! command -v yq &> /dev/null; then
    echo "yq not found. Installing yq using snap..."
    if command -v snap &> /dev/null; then
        sudo snap install yq
    else
        echo "Snap is not installed on this system. Please install snap and then use it to install yq, or install yq manually."
        exit 1
    fi
else
    echo "yq is already installed."
fi

# Ensure the values.yaml file has correct ownership and permissions
echo "Ensuring correct ownership and permissions for values.yaml..."
sudo chown -R $(whoami):$(whoami) /home/mgmt
sudo chmod -R 777 /home/mgmt

# Step 1: Get the Node IP dynamically (only IPv4)
NODE_IP=$(kubectl --kubeconfig=$KUBECONFIG get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
if [ -z "$NODE_IP" ]; then
    echo "Error: Unable to retrieve the IPv4 Node IP."
    exit 1
fi

echo "Node IPv4 identified: $NODE_IP"

# Step 2: Apply the pushgateway manifest
echo "Applying Pushgateway manifest..."
kubectl --kubeconfig=$KUBECONFIG apply -f $PUSHGATEWAY_MANIFEST
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply Pushgateway manifest."
    exit 1
fi

# Step 3: Update the values.yaml with the extracted Node IP for Pushgateway
echo "Updating values.yaml with Pushgateway target under prometheusSpec..."
yq eval ".prometheus.prometheusSpec.additionalScrapeConfigs = [{\"job_name\": \"pushgateway\", \"static_configs\": [{\"targets\": [\"$NODE_IP:30091\"]}]}]" -i $VALUES_FILE
if [ $? -ne 0 ]; then
    echo "Error: Failed to update values.yaml."
    exit 1
fi

# Step 4: Upgrade the Helm release to apply the changes
echo "Upgrading Prometheus Helm release..."
helm --kubeconfig=$KUBECONFIG upgrade -f $VALUES_FILE $HELM_RELEASE_NAME $HELM_CHART -n $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Error: Failed to upgrade Prometheus Helm release."
    exit 1
fi

# Step 5: Delete Prometheus pods to apply the updated configuration
echo "Deleting Prometheus pods to apply the updated configuration..."
kubectl --kubeconfig=$KUBECONFIG delete pods -l app.kubernetes.io/name=prometheus -n $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Error: Failed to delete Prometheus pods."
    exit 1
fi

echo "Prometheus configured to scrape Pushgateway at $NODE_IP:30091 successfully. Pods restarted to apply changes."

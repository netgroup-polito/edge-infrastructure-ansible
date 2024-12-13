#!/bin/bash

# Function to get the local node IP
get_local_ip() {
  kubectl get nodes -o wide | awk 'NR==2 {print $6}' # Adjust this as needed for your cluster
}

# Validate input arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <remoteip>"
  exit 1
fi

REMOTE_IP=$1
LOCAL_IP=$(get_local_ip)

if [ -z "$LOCAL_IP" ]; then
  echo "Error: Unable to determine local node IP."
  exit 1
fi

# Paths
MANIFEST_PATH="/home/mgmt/edge-infrastructure-ansible-main/setup/pushgateway/kmp.yaml"
PROCESSED_MANIFEST_PATH="/home/mgmt/edge-infrastructure-ansible-main/setup/pushgateway/processed_kmp.yaml"

# Replace placeholders in the manifest
echo "Replacing placeholders in the manifest..."
sed -e "s/{{ localip }}/$LOCAL_IP/g" \
    -e "s/{{ remoteip }}/$REMOTE_IP/g" \
    "$MANIFEST_PATH" > "$PROCESSED_MANIFEST_PATH"

# Apply the manifest to the Kubernetes cluster
echo "Applying the manifest to the cluster..."
kubectl apply -f "$PROCESSED_MANIFEST_PATH"

# Cleanup
rm "$PROCESSED_MANIFEST_PATH"
echo "Manifest applied successfully!"

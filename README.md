# Build cluster
# Install and configure CloudEOS
# Install and configure Cilium
Download the installation yaml:
wget f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml

Disable the tunneling:

kubectl create -f quick-install.yaml


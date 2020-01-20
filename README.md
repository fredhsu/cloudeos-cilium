# Testing CloudEOS with Cilium
# Directories
## packer
Packer image definitions to build AMIs for the Kubernetes nodes, including kubeadm dependencies and yaml files in the build
`packer build kubenode-aws.json`
## terraform
Terraform templates to deploy the cluster

## kubernetes
Deployment YAML files and token generated for the cluster

## scripts
shell scripts to deploy the cluster

# Build cluster
## Install and configure CloudEOS
## Install and configure Cilium
Download the installation yaml:
wget f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml

Disable the tunneling:

kubectl create -f quick-install.yaml

Testing connectivity
Mediabot:
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.6/examples/kubernetes-dns/dns-sw-app.yaml


#!/bin/bash
kubeadm init --token maay98.cujupw1teh7ftuyh --pod-network-cidr 10.217.0.0/16
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# Wait for worker nodes to join
until kubectl get nodes ip-10-20-2-22
do
        echo "Waiting for node"
        sleep 1
done

kubectl annotate node ip-10-20-2-21 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-22 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-21 arista/bgp-local-as="65130"
kubectl annotate node ip-10-20-2-22 arista/bgp-local-as="65130"
kubectl taint nodes --all node-role.kubernetes.io/master-
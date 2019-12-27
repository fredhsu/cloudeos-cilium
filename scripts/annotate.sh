#!/bin/bash
kubectl annotate node ip-10-20-2-21 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-22 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-21 arista/bgp-local-as="65130"
kubectl annotate node ip-10-20-2-22 arista/bgp-local-as="65130"
kubectl taint nodes --all node-role.kubernetes.io/master-


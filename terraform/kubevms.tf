terraform {
  backend "remote" {
    organization = "aristanetworks"

    workspaces {
      name = "cloudeos-cilium"
    }
  }
}

locals {
  subnet_id = "subnet-09a396454b18c6683"
  key_name = "cilium-test-kp"
  cloudeos_user_data = <<EOF
%EOS-STARTUP-CONFIG-START%
! EOS startup config
router bgp 65130
neighbor 10.20.2.21 remote-as 65130
neighbor 10.20.2.21 route-reflector-client
neighbor 10.20.2.22 remote-as 65130
neighbor 10.20.2.22 route-reflector-client
%EOS-STARTUP-CONFIG-END%
EOF

  kube_master_user_data = <<EOF
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
        sleep 2
done

kubectl annotate node ip-10-20-2-21 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-22 arista/bgp-peer-ip-1="10.20.2.10"	
kubectl annotate node ip-10-20-2-21 arista/bgp-local-as="65130"
kubectl annotate node ip-10-20-2-22 arista/bgp-local-as="65130"
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl apply -f cilium.yaml
kubectl apply -f cloudeos.yaml

EOF

  kube_worker_user_data = <<EOF
#!/bin/bash
sudo kubeadm join --token maay98.cujupw1teh7ftuyh --discovery-token-unsafe-skip-ca-verification 10.20.2.21:6443
  EOF
}

provider "aws" {
  region = "us-west-2"
  shared_credentials_file = "/Users/fredlhsu/.aws/creds"
}

data "local_file" "kube_master_user_data" {
  filename  = "../scripts/master.sh"
}

data "local_file" "kube_worker_user_data" {
  filename  = "../scripts/worker.sh"
}

data "aws_ami" "kube-node" {
      filter {
        name = "name"
        values = ["packer-ubuntu1804-aws-kube*"]
      }
      owners = ["083837402522"]
      most_recent = true
}


resource "aws_instance" "kube-node-1" {
  ami           = "${data.aws_ami.kube-node.id}"
  instance_type = "t2.medium"
  subnet_id = local.subnet_id
  private_ip = "10.20.2.21"
  source_dest_check = false
  key_name = local.key_name
  root_block_device {
        volume_size = 16
    }
  tags = {
    Name = "kube-node-1"
    User = "fredlhsu"
  }
  user_data = local.kube_master_user_data
}

resource "aws_instance" "kube-node-2" {
  ami           = "${data.aws_ami.kube-node.id}"
  instance_type = "t2.medium"
  subnet_id = local.subnet_id
  private_ip = "10.20.2.22"

  source_dest_check = false
  key_name = local.key_name
  root_block_device {
        volume_size = 16
    }
  tags = {
    Name = "kube-node-2"
    User = "fredlhsu"
  }
  user_data = local.kube_worker_user_data

}

data "aws_ami" "cloudEOS" {
      filter {
      name = "name"
      values = ["vEOS*"]
       }
      owners =  ["679593333241"]
      most_recent = true
}

resource "aws_instance" "cloudeos-node-1" {
  ami           = "${data.aws_ami.cloudEOS.id}"
  instance_type = "c5.xlarge"
  subnet_id = local.subnet_id
  private_ip = "10.20.2.10"
  key_name = local.key_name
  source_dest_check = false
  user_data_base64 = base64encode(local.cloudeos_user_data)


  tags = {
    Name = "cloudeos-node-1"
    User = "fredlhsu"
  }
}

resource "aws_route" "node1-route" {
  route_table_id            = "rtb-99e4dae1"
  destination_cidr_block    = "10.227.0.0/24"
  instance_id = "${aws_instance.kube-node-1.id}"
  depends_on                = ["aws_instance.kube-node-1"]
}

resource "aws_route" "node2-route" {
  route_table_id            = "rtb-99e4dae1"
  destination_cidr_block    = "10.227.1.0/24"
  instance_id = "${aws_instance.kube-node-2.id}"
  depends_on                = ["aws_instance.kube-node-2"]
}


output "node-1-fqdn" {
  value = aws_instance.kube-node-1.public_dns
}
output "node-2-fqdn" {
  value = aws_instance.kube-node-2.public_dns
}
output "cloudeos-node-1-fqdn" {
  value = aws_instance.cloudeos-node-1.public_dns
}

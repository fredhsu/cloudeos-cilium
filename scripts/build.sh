#!/bin/bash
. ~/fetch_aws_creds.sh
cd ../terraform
terraform apply -auto-approve 

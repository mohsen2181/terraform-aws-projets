#!/bin/bash

dnf install -y amazon-efs-utils

mkdir -p /mnt/efs

EFS_ID="${efs_id}"
AP_ID="${ap_id}"
REGION="eu-west-3"
EFS_DNS="${efs_dns}"

for i in {1..12}; do
  nslookup $EFS_DNS && break
  sleep 10
done

for i in {1..12}; do
  mount -t efs -o tls,accesspoint=$AP_ID $EFS_ID:/ /mnt/efs && break
  sleep 10
done
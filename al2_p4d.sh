#!/bin/bash

# To use as user_data
# wget https://raw.githubusercontent.com/indhub/bootstrap_ami/main/al2_p4d.sh
# bash al2_p4d.sh

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/user_data.log 2>&1

# Basics
yum update -y
yum groupinstall "Development Tools" -y
amazon-linux-extras install epel -y

# Install kernel headers
yum install -y wget kernel-devel-$(uname -r) kernel-headers-$(uname -r)

# Install CUDA driver and fabric manager
yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum install -y cuda-drivers-fabricmanager

# Start Fabric Manager
systemctl enable nvidia-fabricmanager
systemctl start nvidia-fabricmanager

# EFA
curl -O https://efa-installer.amazonaws.com/aws-efa-installer-1.14.1.tar.gz
tar -xf aws-efa-installer-1.14.1.tar.gz && cd aws-efa-installer
./efa_installer.sh -y -g

# FSX
amazon-linux-extras install -y lustre2.10

# Install Enroot
arch=$(uname -m)
yum install -y epel-release
yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot-3.4.0-2.el7.${arch}.rpm
yum install -y https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot+caps-3.4.0-2.el7.${arch}.rpm

# Enroot config
echo "ENROOT_LIBRARY_PATH        /usr/lib/enroot"                >>  /tmp/enroot.conf
echo "ENROOT_SYSCONF_PATH        /etc/enroot"                    >> /tmp/enroot.conf
echo "ENROOT_RUNTIME_PATH        /enroot/runtime"                >> /tmp/enroot.conf
echo "ENROOT_CONFIG_PATH         /home/ec2-user/.config/enroot"  >> /tmp/enroot.conf
echo "ENROOT_CACHE_PATH          /enroot/cache"                  >> /tmp/enroot.conf
echo "ENROOT_DATA_PATH           /fsx/enroot/data"               >> /tmp/enroot.conf

# Create directories for enroot
mkdir -p /etc/enroot
mv -f /tmp/enroot.conf /etc/enroot/enroot.conf
mkdir -p /enroot/runtime
mkdir -p /enroot/cache
chown ec2-user:ec2-user /enroot/runtime
chown ec2-user:ec2-user /enroot/cache

#!/bin/bash

sudo growpart /dev/nvme0n1 2
sudo pvresize /dev/nvme0n1p2
sudo lvextend -L+10G /dev/VolGroup00/rootVol
sudo lvextend -L+20G /dev/VolGroup00/varVol
sudo lvextend -L+20G /dev/VolGroup00/homeVol
sudo resize2fs /dev/VolGroup00/rootVol
sudo resize2fs /dev/VolGroup00/varVol
sudo resize2fs /dev/VolGroup00/homeVol

chmod 600 ~/.ssh/id_rsa

sudo yum install -y --nogpgcheck yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
mkdir bootstrap
cd bootstrap
yumdownloader --resolve bzip2 zip unzip yum-utils docker-ce docker-ce-cli containerd.io

cd ..

#!/bin/bash

chmod 600 ~/.ssh/id_rsa

sudo yum install -y --nogpgcheck yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
mkdir bootstrap
cd bootstrap
yumdownloader --resolve bzip2 zip unzip yum-utils docker-ce docker-ce-cli containerd.io

cd ..

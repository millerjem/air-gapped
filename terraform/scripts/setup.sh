#!/bin/bash


chmod 600 ~/.ssh/id_rsa

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
mkdir bootstrap
cd bootstrap
yumdownloader --resolve bzip2 zip unzip yum-utils docker-ce docker-ce-cli containerd.io

cd ..
#scp -i ~/.ssh/airgap.pem -r bootstrap 10.0.2.162:~/.
#scp -i ~/.ssh/airgap.pem konvoy_air_gapped_v1.6.0-rc.2_linux.tar.bz2 10.0.2.162:~/.

#ssh -i ~/.ssh/airgap.pem 10.0.2.162
#sudo yum install bootstrap/*.rpm -y
#sudo systemctl enable --now docker
#sudo usermod -aG docker centos
#newgrp docker
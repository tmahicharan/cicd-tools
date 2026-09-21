#!/bin/bash

set -e

# Resize disk
growpart /dev/nvme0n1 4

lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -l +100%FREE /dev/mapper/RootVG-homeVol

xfs_growfs /
xfs_growfs /var
xfs_growfs /home

# Add Jenkins repo (current URL)
sudo curl -fsSL -o /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/rpm/jenkins.repo

# Import Jenkins GPG key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install dependencies
sudo yum install fontconfig java-21-openjdk -y

# Refresh yum's repo cache so it actually reads the new file
sudo yum clean all && sudo yum makecache

# Install Jenkins
sudo yum install jenkins -y
sudo systemctl daemon-reload

# Enable and start it
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
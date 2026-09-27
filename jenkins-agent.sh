#!/bin/bash

#resize disk from 20GB to 50GB
growpart /dev/nvme0n1 4

lvextend -L +10G /dev/mapper/RootVG-varVol
lvextend -L +10G /dev/mapper/RootVG-rootVol
lvextend -l +100%FREE /dev/mapper/RootVG-homeVol

xfs_growfs /
xfs_growfs /var
xfs_growfs /home

# This is mandatory, nodejs installtion will break SSH if we dont update these packages
dnf update -y openssl\* openssh\* -y
sudo yum install fontconfig java-21-openjdk -y

# Force Java 21 as the default 'java' on PATH.
# java-17-openjdk (pre-installed on this AMI) registers with a higher
# alternatives priority than java-21-openjdk, so `java` silently resolves
# to 17 even after installing 21 unless we set it explicitly. This breaks
# the Jenkins agent (remoting.jar needs 21+, fails with UnsupportedClassVersionError).
JAVA21_BIN=$(alternatives --display java | grep -oP '/usr/lib/jvm/java-21-openjdk[^ ]+/bin/java' | head -n1)
if [ -n "$JAVA21_BIN" ]; then
  sudo alternatives --set java "$JAVA21_BIN"
else
  echo "WARNING: could not locate java-21-openjdk binary via alternatives"
fi
java -version 2>&1 | grep -q '"21' && echo "Java default set to 21 OK" || echo "WARNING: java default is NOT 21 after alternatives --set"

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
dnf install nodejs -y

# docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Terraform
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.68.2

# Maven
dnf install maven -y

# Python
dnf install python3 gcc python3-devel -y

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh

# eksctl and kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl  /usr/local/bin && export PATH=$HOME/bin:$PATH

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl
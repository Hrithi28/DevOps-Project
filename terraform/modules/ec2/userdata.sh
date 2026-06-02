#!/bin/bash
set -euo pipefail

echo "=== Bootstrapping Jenkins server ==="

# System update
yum update -y

# Install Java 17 (required for Jenkins)
yum install -y java-17-amazon-corretto-headless

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins
usermod -aG docker ec2-user

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install Git
yum install -y git

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Print initial admin password location
echo "=== Jenkins initial admin password ==="
echo "Run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "Jenkins will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

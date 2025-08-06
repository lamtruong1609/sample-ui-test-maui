#!/bin/bash

# Update system
sudo dnf update -y

# Install Java 17, Git, curl, and nano
sudo dnf install -y java-17-amazon-corretto git curl nano

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create and enable 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab

# Install ADB (Android Debug Bridge)
cd ~
curl -O https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# Add ADB to PATH
echo 'export PATH=$PATH:$HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Test ADB installation
which adb
adb version
adb devices

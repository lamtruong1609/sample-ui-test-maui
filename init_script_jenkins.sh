#!/bin/bash

# Update system
sudo dnf update -y

# Install Java 17, Git
sudo dnf install -y java-17-amazon-corretto git

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user  # or use $(whoami) if not EC2

# Install Docker Compose V2 (as a plugin)
sudo dnf install -y docker-compose-plugin
# Note: Use 'docker compose' (with a space) instead of 'docker-compose'

# Create and enable 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab 
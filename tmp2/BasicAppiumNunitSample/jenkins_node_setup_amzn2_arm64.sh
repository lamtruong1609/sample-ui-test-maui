#!/bin/bash
set -e

# Update and install Java (for Jenkins)
sudo yum update -y
sudo yum install -y java-17-amazon-corretto

# Create 2GB swap file
if [ ! -f /swapfile ]; then
  sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Install Git
sudo yum install -y git

# Install Node.js (LTS, ARM64)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install Appium globally
sudo npm install -g appium

# Install .NET 7 SDK (ARM64)
# Add Microsoft package repository for Amazon Linux 2 ARM64
dotnet_rpm_url="https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm"
wget $dotnet_rpm_url -O packages-microsoft-prod.rpm
sudo rpm -Uvh packages-microsoft-prod.rpm
rm packages-microsoft-prod.rpm
sudo yum install -y dotnet-sdk-7.0

# Install Android tools (for Android UI tests)
sudo yum install -y android-tools wget unzip

# Download and set up Android SDK command line tools
ANDROID_SDK_ROOT=$HOME/Android/Sdk
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
cd "$ANDROID_SDK_ROOT/cmdline-tools"
if [ ! -d latest ]; then
  wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
  unzip cmdline-tools.zip
  mv cmdline-tools latest
  rm cmdline-tools.zip
fi

# Add Android SDK to PATH (add to ~/.bashrc for persistence)
grep -qxF "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" ~/.bashrc || echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
grep -qxF "export PATH=\$PATH:$ANDROID_SDK_ROOT/latest/bin:$ANDROID_SDK_ROOT/platform-tools" ~/.bashrc || echo "export PATH=\$PATH:$ANDROID_SDK_ROOT/latest/bin:$ANDROID_SDK_ROOT/platform-tools" >> ~/.bashrc

# Accept Android SDK licenses and install platform tools (run as user, not root)
$ANDROID_SDK_ROOT/latest/bin/sdkmanager --licenses || true
$ANDROID_SDK_ROOT/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Install Appium driver for Android
appium driver install uiautomator2

echo "Node agent pre-init complete. Please restart your shell or source ~/.bashrc to update PATH." 
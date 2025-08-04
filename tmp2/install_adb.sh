cd ~
curl -O https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

echo 'export PATH=$PATH:$HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

which adb
adb version
adb devices

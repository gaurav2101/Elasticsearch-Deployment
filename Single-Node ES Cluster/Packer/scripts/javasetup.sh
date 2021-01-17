#### Java Installation ####
#!/bin/bash
curl -L https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.tar.gz -o java.tar.gz
sudo mkdir /usr/local/java
sudo tar -xvf java.tar.gz -C /usr/local/java --strip-components=1
sudo update-alternatives --install /usr/bin/jar jar /usr/local/java/bin/jar 100
sudo update-alternatives --install /usr/bin/java java /usr/local/java/bin/java 100
sudo update-alternatives --install /usr/bin/javac javac /usr/local/java/bin/javac 100
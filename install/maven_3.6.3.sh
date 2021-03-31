#!/bin/bash
source ./My.sh

# Maven 3.6.3 在线安装
mkdir -m 777 -p '/home/install'
cd '/home/install'

rm -rf 'apache-maven-3.6.3-bin.tar.gz'
apache_maven_bin_url='https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz'
wget "$apache_maven_bin_url"

mkdir -m 777 -p '/usr/local/maven/'
rm -rf '/usr/local/maven/apache-maven-3.6.3'
tar -zxvf 'apache-maven-3.6.3-bin.tar.gz' -C '/usr/local/maven/'

# 手动修改配置文件：/usr/local/maven/apache-maven-3.6.3/conf/settings.xml

echo '' >> '/etc/profile'
echo '# Maven' >> '/etc/profile'
echo 'MAVEN_HOME=/usr/local/maven/apache-maven-3.6.3' >> '/etc/profile'
echo 'export PATH=${MAVEN_HOME}/bin:${PATH}' >> '/etc/profile'
echo '' >> '/etc/profile'
cat '/etc/profile'

# OpenJDK 1.8 在线安装
yum install -y 'java-1.8.0-openjdk-demo.x86_64'

source /etc/profile
mvn -v

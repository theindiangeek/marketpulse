#!/bin/bash
#Task: https://paper.dropbox.com/doc/Devops-Coding-Test-2-ncHx8O1kZ9H9OQbMGHWQP

#1. System settings
sudo su

#Enable SSH
yum install openssh-server.x86_64 -y
service sshd start

#Secure machine (you can think of ways to secure it. Any top 3 things will be enough)
sed -i 's/.*PermitRootLogin.*/#PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#Port/Port/' /etc/ssh/sshd_config
sed -i 's/Port.*/Port 48157/' /etc/ssh/sshd_config
service sshd restart

echo sshd: 1.2.3.4 >> /etc/hosts.deny

#Disable Bash History
echo 'set +o history' >> ~/.bashrc
source ~/.bashrc
set +o history

#Set ulimit to 10000
ulimit -n 10000
sed -i "\$s/\$/\nhard nofile 10000/" /etc/security/limits.conf
sed -i "\$s/\$/\nsoft nofile 10000/" /etc/security/limits.conf

#Set net.netfilter.nf_conntrack_max value to 3097152
echo net.netfilter.nf_conntrack_max=3097152 >> /etc/sysctl.conf
sysctl -p

#Install Curl
yum install curl -y


#Setup 3 instances running Postgresql master/slave setup
yum install docker -y
service docker start
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
docker build -t postgres:v1 .
yum install postgresql.x86_64 -y
docker-compose up -d

#Verify Master instance to allow write operations
PGPASSWORD=postgres psql -h localhost -p 5432 -Upostgres postgres -c 'CREATE DATABASE testing;'

#Verify Slave instance to allow only read operations
PGPASSWORD=postgres psql -h localhost -p 5433 -Upostgres postgres -c 'CREATE DATABASE testing;'

#Verify all Slave instances are in sync
PGPASSWORD=postgres psql -h localhost -p 5432 -Upostgres postgres -c '\l'
PGPASSWORD=postgres psql -h localhost -p 5433 -Upostgres postgres -c '\l'
PGPASSWORD=postgres psql -h localhost -p 5434 -Upostgres postgres -c '\l'

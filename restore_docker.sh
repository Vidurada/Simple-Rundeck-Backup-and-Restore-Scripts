#!/bin/bash

sudo yum install wget -y
sudo yum install unzip -y

sudo dnf install python3-pip -y
pip3 install awscli --upgrade --user


sudo dnf install -y dnf-utils device-mapper-persistent-data lvm2
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce --nobest -y

sudo systemctl start docker

mkdir /home/ec2-user/DockerBackup
aws s3 cp s3://viduras-test-bucket/DockerBackup /home/ec2-user/DockerBackup --recursive

sudo docker login --username <username> --password <password>   #add valid username and password here
my_ip=$( curl http://checkip.amazonaws.com )
sudo docker create --name ust-rundeck -v /home/ec2-user/DockerBackup/Data:/home/rundeck/server/data -v /home/ec2-user/DockerBackup/logs:/home/rundeck/var/logs -v /home/ec2-user/DockerBackup/api:/home/rundeck/etc/api -p 4440:4440 -e RUNDECK_GRAILS_URL=http://$my_ip:4440 vidurada/rundeck:1.0
sudo docker start ust-rundeck

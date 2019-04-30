#!/bin/bash

#install java, rundeck,rd and unzip
cd /home/ec2-user/
sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel -y
sudo rpm -Uvh http://repo.rundeck.org/latest.rpm
sudo yum install rundeck -y
sudo yum install wget -y
sudo wget https://bintray.com/rundeck/rundeck-rpm/rpm -O bintray.repo
sudo mv bintray.repo /etc/yum.repos.d/
sudo yum install rundeck-cli -y
sudo /etc/init.d/rundeckd stop
sudo yum install unzip -y

#config rd
my_ip=$( curl http://checkip.amazonaws.com )
echo $my_ip
echo "export RD_CONF=/etc/rundeck/rd.conf" >> /home/ec2-user/envir.sh
echo "export RD_URL=http://$my_ip:4440/api/30" >> /home/ec2-user/envir.sh
echo "export RD_USER=vidura.d" >> /home/ec2-user/envir.sh   #add rundeck username here
echo "export RD_PASSWORD=vidura@93" >> /home/ec2-user/envir.sh  #add rundeck password here

chmod +x  /home/ec2-user/envir.sh
source /home/ec2-user/envir.sh

#config rundeck
sudo sed -i "s/localhost/$my_ip/g" /etc/rundeck/rundeck-config.properties
sudo sed -i "s/localhost/$my_ip/g" /etc/rundeck/framework.properties

#install aws cli
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip /home/ec2-user/awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

#download backup files from s3
mkdir /home/ec2-user/rundeckBackup
aws s3 cp s3://viduras-test-bucket/rundeckBackup /home/ec2-user/rundeckBackup --recursive

#restore folders
for entry in "/home/ec2-user/rundeckBackup"/*; do
    if [[ -d $entry ]]; then
        bk_folder=$( basename $entry  )
        if [[ $bk_folder != 'Projects' ]]; then
                sudo rm -rf /var/lib/rundeck/$bk_folder
                sudo cp -r /home/ec2-user/rundeckBackup/$bk_folder /var/lib/rundeck/
        fi
    fi
done

#restore gmail api
sudo cp /home/ec2-user/rundeckBackup/gmailApiCredentials.json /var/lib/rundeck/weekly-mail/gmailApiCredentials.json

#replace the realm.properties file
sudo rm -rf /etc/rundeck/realm.properties
sudo cp /home/ec2-user/rundeckBackup/realm.properties /etc/rundeck/realm.properties

sudo /etc/init.d/rundeckd start


#restore jobs
sleep 120
for entry in "/home/ec2-user/rundeckBackup/Projects"/*; do
    if [[ -d $entry ]]; then
        project_name=$( basename $entry )
        rd projects create -p $project_name
        rd jobs load -f  /home/ec2-user/rundeckBackup/Projects/$project_name/jobs.xml -p $project_name
    fi
done

#install python3 and pip
wget https://www.python.org/ftp/python/3.6.8/Python-3.6.8.tgz
tar xf Python-3.*
cd Python-3.*
./configure
make
make altinstall
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python get-pip.py

#install required dependencies from requirements file
cd /home/ec2-user/rundeckBackup/
filename="requirements.txt"
while read -r line; do
    name="$line"
    sudo pip install $line
done < "$filename"

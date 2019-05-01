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
echo "Java, Rundeck, Rundeck-Cli, wget and unzip Installed Successfully" >> /home/ec2-user/install_status.txt

#config rd
my_ip=$( curl http://checkip.amazonaws.com )
echo "This Machine's IP Address is :$my_ip"  >> /home/ec2-user/install_status.txt
echo "export RD_CONF=/etc/rundeck/rd.conf" >> /home/ec2-user/envir.sh
echo "export RD_URL=http://$my_ip:4440/api/30" >> /home/ec2-user/envir.sh
echo "export RD_USER=vidura.d" >> /home/ec2-user/envir.sh   #add rundeck username here
echo "export RD_PASSWORD=vidura@93" >> /home/ec2-user/envir.sh  #add rundeck password here

chmod +x  /home/ec2-user/envir.sh
source /home/ec2-user/envir.sh

echo "Env parameters added" >> /home/ec2-user/install_status.txt

#config rundeck
sudo sed -i "s/localhost/$my_ip/g" /etc/rundeck/rundeck-config.properties
sudo sed -i "s/localhost/$my_ip/g" /etc/rundeck/framework.properties

echo "Env parameters added" >> /home/ec2-user/install_status.txt

#install aws cli
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip /home/ec2-user/awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

#download backup files from s3
mkdir /home/ec2-user/rundeckBackup
aws s3 cp s3://viduras-test-bucket/rundeckBackup /home/ec2-user/rundeckBackup --recursive

echo "AWS-Cli installed and downloaded backup from S3" >> /home/ec2-user/install_status.txt

#restore folders
for entry in "/home/ec2-user/rundeckBackup"/*; do
    if [[ -d $entry ]]; then
        bk_folder=$( basename $entry  )
        if [[ $bk_folder != 'Projects' ]]; then
                sudo cp -rp /home/ec2-user/rundeckBackup/$bk_folder/. /var/lib/rundeck/$bk_folder
        fi
    fi
done

echo "All the config folders are restored" >> /home/ec2-user/install_status.txt

#restore gmail api
sudo cp -p /home/ec2-user/rundeckBackup/gmailApiCredentials.json /var/lib/rundeck/weekly-mail/gmailApiCredentials.json

#replace the realm.properties file
sudo rm -rf /etc/rundeck/realm.properties
sudo cp -p /home/ec2-user/rundeckBackup/realm.properties /etc/rundeck/realm.properties

sudo /etc/init.d/rundeckd start

echo "Additional config files are restored" >> /home/ec2-user/install_status.txt


#restore jobs
sleep 120
for entry in "/home/ec2-user/rundeckBackup/Projects"/*; do
    if [[ -d $entry ]]; then
        project_name=$( basename $entry )
        rd projects create -p $project_name
        rd jobs load -f  /home/ec2-user/rundeckBackup/Projects/$project_name/jobs.xml -p $project_name
    fi
done
echo "Projects restored" >> /home/ec2-user/install_status.txt

#install python3 and pip
wget -P /home/ec2-user/ https://www.python.org/ftp/python/3.6.0/
tar xf /home/ec2-user/Python-3.*
cd /home/ec2-user/Python-3.*
./configure
make
make altinstall
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python get-pip.py

echo "Python 3.6.0 installed" >> /home/ec2-user/install_status.txt

#install required dependencies from requirements file
cd /home/ec2-user/rundeckBackup/
filename="requirements.txt"
while read -r line; do
    name="$line"
    sudo pip install $line
done < "$filename"

echo "Additional Dependencies Installed" >> /home/ec2-user/install_status.txt

#!/usr/bin/env bash

cd ~

#the projects that should be back up. To add more projects add their names in the list
declare -a projects=("DAILY-OPERATIONS" "testing01")
#the folders needed to back up. To add more config folders add their names in the list
declare -a folders=("data" "logs")

#find if there any previous backup and delete
if [ -d "rundeckBackup" ]; then
      rm -rf ~/rundeckBackup
      echo "Previous Backup Detected"
      echo "Previous Backup Deleted"
fi

#backup the projects
for i in "${projects[@]}"
do
  mkdir -p ~/rundeckBackup/Projects/$i
  rd jobs list -f ~/rundeckBackup/Projects/$i/jobs.xml -p $i
  echo "$i project backed up in ~/rundeckBackup/Projects/$1/jobs.xml"
done

#backup folders
for i in "${folders[@]}"
do
  cp -rpa /var/lib/rundeck/$i rundeckBackup/$i
  echo "$i backed up in rundeckBackup/$1"
done

#back up realm.properties file. This file contains information of rundeck users
sudo cp /etc/rundeck/realm.properties rundeckBackup/
sudo chmod 777 rundeckBackup/realm.properties

#backup gmailApiCredentials to S3
sudo cp /var/lib/rundeck/weekly-mail/gmailApiCredentials.json rundeckBackup/
sudo cp /var/lib/rundeck/DAYSTAT-UPDATE/Quickstart-671a324109fa.json rundeckBackup/

#upload the files to s3 bucket
aws s3 sync ~/rundeckBackup s3://ust-rundeck-backup/rundeckBackup
echo "Backup Complete"

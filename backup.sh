#!/usr/bin/env bash

cd ~

#the projects that should be backed up
declare -a projects=("DAILY-OPERATIONS" "testing01")
#the folders needed to back up
declare -a folders=("data" "logs")

#find if there any previous backup and delete
if [ -d "rundeckBackup" ]; then
      rm -rf ~/rundeckBackup
      echo "Delete the previous backup"
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
  cp -r /var/lib/rundeck/$i rundeckBackup/$i
  echo "$i backed up in rundeckBackup/$1"
done

#back up realm.properties file. This file contains information of rundeck users
sudo cp /etc/rundeck/realm.properties rundeckBackup/
sudo chmod 777 rundeckBackup/realm.properties

#upload the files to s3 bucket
aws s3 sync ~/rundeckBackup s3://ust-rundeck-backup/rundeckBackup
echo "Backup Complete"

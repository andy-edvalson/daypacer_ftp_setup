#!/bin/bash

add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
add-apt-repository "deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner"
apt-get update
apt-get install -y pure-ftpd pureadmin awscli lftp sox

sudo groupadd ftpgroup
sudo useradd -g ftpgroup -d /dev/null -s /etc ftpuser

sudo mkdir /home/ftpusers
sudo mkdir /home/ftpusers/recordings

echo "Enter password for user: recordings"
sudo pure-pw useradd recordings -u ftpuser -d /home/ftpusers/recordings
sudo pure-pw mkdb

sudo ln -s /etc/pure-ftpd/pureftpd.passwd /etc/pureftpd.passwd
sudo ln -s /etc/pure-ftpd/pureftpd.pdb /etc/pureftpd.pdb
sudo ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/PureDB
sudo echo "29799 29899" > /etc/pure-ftpd/conf/PassivePortRange
sudo chown -hR ftpuser:ftpgroup /home/ftpusers/

sudo cp pure-ftpd.conf /etc/pure-ftpd/
sudo cp upload_script.sh /usr/local/bin
sudo cp cleanup.sh /usr/local/bin
sudo cp launch_ftp_upload.sh /usr/local/bin
sudo cp pure-ftpd-common /etc/default
echo "yes" > /etc/pure-ftpd/conf/CallUploadScript

(sudo crontab -l ; echo "* 4 * * * /usr/local/bin/cleanup.sh") | sort - | uniq - | sudo crontab -

/etc/init.d/pure-ftpd restart


#sudo pure-uploadscript -B -r /usr/local/bin/upload_script.sh

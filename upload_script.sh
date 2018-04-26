#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been uploaded" >> /tmp/ftp.log
echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log
echo "" >> /tmp/ftp.log

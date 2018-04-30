#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been uploaded" >> /tmp/ftp.log
echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log
#lftp -c "open -u recordings,daypacer localhost; put -O / README.md"
echo "" >> /tmp/ftp.log
lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '$1'"


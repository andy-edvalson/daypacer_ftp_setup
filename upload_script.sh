#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been received." >> /tmp/ftp.log
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

declare FILESPEC=$1
declare REGEX="([a-z\/])+(recording\.([0-9]+)_([0-9A-Z]+)_([a-zA\@\.]+)_([a-zA-Z\ \_]+)_([0-9]+)_([0-9]+)_([0-9]+).wav)"

if [[ $FILESPEC =~ $REGEX ]]
then
        filename="${BASH_REMATCH[2]}"
        phone="${BASH_REMATCH[3]}"
        email="${BASH_REMATCH[5]}"
        campaign="${BASH_REMATCH[6]}"
        month="${BASH_REMATCH[7]}"
        day="${BASH_REMATCH[8]}"
        year="${BASH_REMATCH[9]}"

        output="s3://daypacer-incoming-recordings/Recordings/$year/$month/$day/$campaign/$filename"
        echo "uploading $FILESPEC to $output" >> /tmp/ftp.log
        aws s3 cp "$FILESPEC" "$output"

fi


echo "relaying $1 to ftp.higheredgrowth.com" >> /tmp/ftp.log
lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '$1'"

echo "" >> /tmp/ftp.log

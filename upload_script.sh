#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been received." >> /tmp/ftp.log
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

declare TMP_REGEX="(.*)(\.tmp[0-9]+)$"
declare FILESPEC=$1

# Temporary hack for five9 upload silliness
if [[ $FILESPEC =~ $TMP_REGEX ]]
then
  	echo "File appears to be incorrectly named, allowing 2 seconds for rename, then stripping off appended portion" >> /tmp/ftp.log
        FILESPEC="${BASH_REMATCH[1]}"
        sleep 2
	if [[ -f $FILESPEC ]]
	then
		echo "Fixed Filename: $FILESPEC" >> /tmp/ftp.log
	else
		echo "$FILESPEC does not appear to exist. Bailing." >> /tmp/ftp.log
		exit 1
	fi
fi

declare REGEX="([a-z\/])+(recording\.([0-9a-zA-Z]*)_([0-9A-Z]+)_([a-zA-Z0-9\@\.]+)_([a-zA-Z0-9\ \_]+)_([0-9]+)_([0-9]+)_([0-9]+).wav)"
echo "relaying $1 to ftp.higheredgrowth.com" >> /tmp/ftp.log
lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '$1'"

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
        echo "moving $FILESPEC to $output" >> /tmp/ftp.log
        aws s3 mv "$FILESPEC" "$output"

fi

echo "" >> /tmp/ftp.log

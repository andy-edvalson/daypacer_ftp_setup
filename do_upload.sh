#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been received." >> /tmp/ftp.log
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

declare REGEX="([a-z\/])+((recording\.)?([0-9a-zA-Z]*)_([0-9A-Z]+)_([a-zA-Z0-9\@\.]+)_([a-zA-Z0-9\ \_]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare TMP_REGEX="(.*)(\.tmp[0-9]+)$"
declare FILESPEC=$1
declare S3_BUCKET='daypacer_incoming_recordings'
declare EDUMAX_TAG_NAME='edumax_status'

# Temporary hack for five9 upload silliness
if [[ $FILESPEC =~ $TMP_REGEX ]]
then
  	echo "File appears to be incorrectly named, allowing 2 seconds for rename, then stripping off appended portion" >> /tmp/ftp.log
        FILESPEC="${BASH_REMATCH[1]}"
        sleep 0.2
	if [[ -f $FILESPEC ]]
	then
		echo "Fixed Filename: $FILESPEC" >> /tmp/ftp.log
	else
		echo "$FILESPEC does not appear to exist. Bailing." >> /tmp/ftp.log
		exit 1
	fi
fi

LENGTH=`sox "$1" -n stat 2>&1 | sed -n 's#^Length (seconds):[^0-9]*\([0-9.]*\)$#\1#p' | awk '{print int($1+0.5)}'`
echo "length is ${LENGTH}"
if (( ${LENGTH} >= 120 ))
then
   declare E_STATUS=sent
else
   declare E_STATUS=too_short
fi

echo "relaying $1 to ftp.higheredgrowth.com" >> /tmp/ftp.log
lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '$1'"

if [[ $FILESPEC =~ $REGEX ]]
then
        filename="${BASH_REMATCH[2]}"
        phone="${BASH_REMATCH[4]}"
        call="${BASH_REMATCH[5]}"
        email="${BASH_REMATCH[6]}"
        campaign="${BASH_REMATCH[7]}"
        month="${BASH_REMATCH[8]}"
        day="${BASH_REMATCH[9]}"
        year="${BASH_REMATCH[10]}"
        hour="${BASH_REMATCH[12]}"
        minute="${BASH_REMATCH[13]}"
        second="${BASH_REMATCH[14]}"
        period="${BASH_REMATCH[15]}"

        output="s3://${S3_BUCKET}/Recordings/$year/$month/$day/$campaign/$filename"
        echo "moving $FILESPEC to $output" >> /tmp/ftp.log
        aws s3 mv "$FILESPEC" "$output"

        # Adding tagging
        TAGGING="TagSet=[{Key=${EDUMAX_TAG_NAME},Value=${E_STATUS}}]"
        aws s3api put-object-tagging --bucket ${S3_BUCKET} --key "Recordings/$year/$month/$day/$campaign/$filename" --tagging "${TAGGING}"
fi

echo "" >> /tmp/ftp.log

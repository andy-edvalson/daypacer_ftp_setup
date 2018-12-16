#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been received." >> /tmp/ftp.log
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\@\._]+.[com|net|org])_([a-zA-Z0-9\ \_\-]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare TMP_REGEX="(.*)(\.tmp[0-9]+)$"
declare FILESPEC=$1
declare S3_BUCKET='daypacer-incoming-recordings'
declare S3_BUCKET_ALL='daypacer-incoming-recordings-all'
declare EDUMAX_TAG_NAME='edumax_status'
#declare AWS_CLI='/home/ubuntu/.local/bin/aws'
declare AWS_CLI='/usr/local/bin/aws'

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
	echo "relaying $1 to ftp.higheredgrowth.com" >> /tmp/ftp.log
	lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '$1'"
   	declare E_STATUS=sent
else
   declare E_STATUS=too_short
   echo "Not sending $1 to edumax (too short)" >> /tmp/ftp.log
fi


if [[ $FILESPEC =~ $REGEX ]]
then
        filename="${BASH_REMATCH[2]}"
        phone="${BASH_REMATCH[4]}"
        ani="${BASH_REMATCH[5]}"
        call="${BASH_REMATCH[6]}"
        email="${BASH_REMATCH[7]}"
        campaign="${BASH_REMATCH[8]}"
        month="${BASH_REMATCH[9]}"
        day="${BASH_REMATCH[10]}"
        year="${BASH_REMATCH[11]}"
        hour="${BASH_REMATCH[13]}"
        minute="${BASH_REMATCH[14]}"
        second="${BASH_REMATCH[15]}"
        period="${BASH_REMATCH[16]}"


        echo "moving $FILESPEC to /data/uploaded/$filename" >> /tmp/s3.log
	mv "$FILESPEC" "/data/uploaded/$filename"

	if (( ${LENGTH} >= 120 ))
	then
 		output="s3://${S3_BUCKET}/Recordings/$year/$month/$day/$campaign/$filename"
       		echo "moving /data/uploaded/$filename to $output" >> /tmp/s3.log
        	${AWS_CLI} s3 cp "/data/uploaded/$filename" "$output" --no-progress >> /tmp/s3.log

        	# Adding tagging
        	TAGGING="TagSet=[{Key=${EDUMAX_TAG_NAME},Value=${E_STATUS}}]"
        	${AWS_CLI} s3api put-object-tagging --bucket ${S3_BUCKET} --key "Recordings/$year/$month/$day/$campaign/$filename" --tagging "${TAGGING}" >> /tmp/s3.log
	fi

 	output="s3://${S3_BUCKET_ALL}/Recordings/$year/$month/$day/$campaign/$filename"
       	echo "moving /data/uploaded/$filename to $output" >> /tmp/s3.log
        ${AWS_CLI} s3 cp "/data/uploaded/$filename" "$output" --no-progress >> /tmp/s3.log

        # Adding tagging
        TAGGING="TagSet=[{Key=${EDUMAX_TAG_NAME},Value=${E_STATUS}}]"
        ${AWS_CLI} s3api put-object-tagging --bucket ${S3_BUCKET_ALL} --key "Recordings/$year/$month/$day/$campaign/$filename" --tagging "${TAGGING}" >> /tmp/s3.log


fi

echo "" >> /tmp/ftp.log

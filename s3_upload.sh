#!/bin/bash
echo "`date -u`" >> /tmp/ftp.log
echo " $1 has been received." >> /tmp/ftp.log
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\@\.]+)_([a-zA-Z0-9\ \_]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare TMP_REGEX="(.*)(\.tmp[0-9]+)$"
declare FILESPEC=$1
declare S3_BUCKET='daypacer-incoming-recordings'
declare S3_BUCKET_ALL='daypacer-incoming-recordings-all'
declare EDUMAX_TAG_NAME='edumax_status'
#declare AWS_CLI='/home/ubuntu/.local/bin/aws'
declare AWS_CLI='/usr/local/bin/aws'

LENGTH=`sox "$1" -n stat 2>&1 | sed -n 's#^Length (seconds):[^0-9]*\([0-9.]*\)$#\1#p' | awk '{print int($1+0.5)}'`
if (( ${LENGTH} >= 120 ))
then
   	declare E_STATUS=sent
else
   declare E_STATUS=too_short
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

	if (( ${LENGTH} >= 120 ))
	then
 		output="s3://${S3_BUCKET}/Recordings/$year/$month/$day/$campaign/$filename"
       		echo "moving $FILESPEC to $output" >> /tmp/s3.log
        	${AWS_CLI} s3 cp "$FILESPEC" "$output" >> /tmp/s3.log

        	# Adding tagging
        	TAGGING="TagSet=[{Key=${EDUMAX_TAG_NAME},Value=${E_STATUS}}]"
        	${AWS_CLI} s3api put-object-tagging --bucket ${S3_BUCKET} --key "Recordings/$year/$month/$day/$campaign/$filename" --tagging "${TAGGING}" >> /tmp/s3.log
	fi

 	output="s3://${S3_BUCKET_ALL}/Recordings/$year/$month/$day/$campaign/$filename"
       	echo "moving $FILESPEC to $output" >> /tmp/s3.log
        ${AWS_CLI} s3 cp "$FILESPEC" "$output" >> /tmp/s3.log

        # Adding tagging
        TAGGING="TagSet=[{Key=${EDUMAX_TAG_NAME},Value=${E_STATUS}}]"
        ${AWS_CLI} s3api put-object-tagging --bucket ${S3_BUCKET_ALL} --key "Recordings/$year/$month/$day/$campaign/$filename" --tagging "${TAGGING}" >> /tmp/s3.log

fi

echo "" >> /tmp/ftp.log

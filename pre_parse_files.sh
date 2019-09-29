#!/bin/bash

declare AWS_CLI='/usr/local/bin/aws'
declare S3_LOGS='/var/log/s3.log'

declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\@\._\-]+\.[comnetorg]{3})_([a-zA-Z0-9\ \_\-]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare OUT_PATH=$2
declare IN_PATH=$1
declare FTP_FLAG=$3
declare MINUTE_DELAY=0

echo "Beginning Pre-parse Job at `date`"

# find all wav files older than an hour
find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | while read f
do

  # if file still exists
  if [[ -f $f ]]
  then

    if [[ $f =~ $REGEX ]]
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

        # multipart call
      	if ([ $period = AM ]) then
		hour_length=`expr length $hour`
		echo "hour length $hour_length"
		if ([ $hour_length = 1 ]) then
        		echo "AM... need to append leading zero to hour"
			hour="0$hour"
		fi
                NEW_FILENAME="${IN_PATH}/${phone}_${ani}_${call}_${email}_${campaign}_${month}_${day}_${year}_${hour}_${minute}_${second} ${period}.wav"
		echo "Renaming $f to $NEW_FILENAME"
		mv "$f" "$NEW_FILENAME"
     	fi

      	if ([ $period = PM ]) then
		if ([ "$hour" -ne "12" ]) then
        		echo "PM and $hour < 12... need to append leading zero to hour"
			hour=$(($hour + 12))
                fi
		NEW_FILENAME="${IN_PATH}/${phone}_${ani}_${call}_${email}_${campaign}_${month}_${day}_${year}_${hour}_${minute}_${second} ${period}.wav"
		echo "Renaming $f to $NEW_FILENAME"
		mv "$f" "$NEW_FILENAME"
      	fi

    fi
  fi
done

echo "Pre-parse job complete at `date`"

#!/bin/bash
echo "$(date -u)" >>/tmp/ftp.log
echo " $1 has been received." >>/tmp/ftp.log
echo " FTP Upload flag set to $2"
#echo "`date -u` `aws s3 cp $1 s3://daypacer-incoming-recordings`" >> /tmp/ftp.log

#declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\-\@\._]+.[com|net|org])_([a-zA-Z0-9\ \_\-]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\@\._\-]+\.[comnetorg]{3})_([a-zA-Z0-9\ \_\-]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare TMP_REGEX="(.*)(\.tmp[0-9]+)$"
declare FILESPEC=$1
declare S3_BUCKET='daypacer-incoming-recordings'
declare S3_BUCKET_ALL='daypacer-incoming-recordings-all'
declare EDUMAX_TAG_NAME='edumax_status'
#declare AWS_CLI='/home/ubuntu/.local/bin/aws'
declare AWS_CLI='/usr/local/bin/aws'

escape_for_execution () {
    local PASS_TO_ESCAPE=$1
    echo $PASS_TO_ESCAPE \
    | sed 's/\\/\\\\/g' # escape backslash
}

do_ftp () {
    FILENAME=$1
    FTP_USER=$2
    FTP_PASS=$(escape_for_execution "$3")  # replace single backslash with triple backslash
    FTP_HOST=$4
    FTP_OUT_PATH=$5
    FTP_LOG_PATH=$6
	FTP_OUT_FILENAME=$7
    FTP_PREFIX_CMD=$8

    mkdir /tmp/$FTP_USER
	cp "$FILENAME" "/tmp/$FTP_USER/$FTP_OUT_FILENAME"
    lftp -c "$FTP_PREFIX_CMD set xfer:log 1; set xfer:log-file $FTP_LOG_PATH; open -u \"$FTP_USER\",\"$FTP_PASS\" $FTP_HOST; put -O $FTP_OUT_PATH /tmp/$FTP_USER/$FTP_OUT_FILENAME"
	rm "/tmp/$FTP_USER/$FTP_OUT_FILENAME"
}

# Temporary hack for five9 upload silliness
if [[ $FILESPEC =~ $TMP_REGEX ]]; then
	echo "File appears to be incorrectly named, allowing 2 seconds for rename, then stripping off appended portion" >>/tmp/ftp.log
	FILESPEC="${BASH_REMATCH[1]}"
	sleep 0.2
	if [[ -f $FILESPEC ]]; then
		echo "Fixed Filename: $FILESPEC" >>/tmp/ftp.log
	else
		echo "$FILESPEC does not appear to exist. Bailing." >>/tmp/ftp.log
		exit 1
	fi
fi

echo $FILESPEC
if [[ $FILESPEC =~ $REGEX ]]; then
	echo "matched"
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

	OUT_FILENAME="${phone}_000_${email}_${month}_${day}_${year}.wav"
	echo "output filename for ftp is ${OUT_FILENAME}"

	echo "length is ${LENGTH}"
	if ([ $2 = true ]); then
		cp "$1" /tmp/${OUT_FILENAME}

		echo "relaying $1 to ftp.higheredgrowth.com" >>/tmp/ftp.log &
		lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp_highered_edutrek.log; open -u edutrek,qWpVjvx^P69b*56# ftp.higheredgrowth.com; put -O / '/tmp/${OUT_FILENAME}'" &

		echo "relaying $1 to ftp.higheredgrowth.com (candid maven)" >>/tmp/ftp.log &
		lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp_highered_candidmaven.log; open -u \"Candid Maven\",\"T,MQv'yq*Y4h][L/\" ftp.higheredgrowth.com; put -O / '/tmp/${OUT_FILENAME}'" &

		echo "relaying $1 to ftp.higheredgrowth.com (provide media)" >>/tmp/ftp.log &
		lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp_highered_provide.log; open -u \"Provide Media\",\".F5\`U<Dfy6+N{(Hr\" ftp.higheredgrowth.com; put -O / '/tmp/${OUT_FILENAME}'" &

		echo "relaying $1 to ftp.higheredgrowth.com (Entropy)" >>/tmp/ftp.log &
		lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp_highered_entropy.log; open -u Entropy,\"mUH2_Op#FrIB\" ftp.higheredgrowth.com; put -O / '/tmp/${OUT_FILENAME}'" &

		# echo "relaying $1 to upload.leadhoop.com (daypacer)" >>/tmp/ftp.log &
		# lftp -c "set ftp:ssl-allow yes; set ssl:verify-certificate false; set xfer:log 1; set xfer:log-file /tmp/lftp_leadhoop_daypacer.log; open -u daypacer_dialer,g)8%L?\&?}FhWC[2x55]\\\ upload.leadhoop.com; put -O / '/tmp/${OUT_FILENAME}'" &

		# echo "relaying $1 to upload.leadhoop.com (path 56)" >>/tmp/ftp.log &
		# lftp -c "set ftp:ssl-allow yes; set ssl:verify-certificate false; set xfer:log 1; set xfer:log-file /tmp/lftp_leadhoop_path56.log; open -u path_56_dialer,Jts^.h.,Ws(3u~z\>?LxD upload.leadhoop.com; put -O / '/tmp/${OUT_FILENAME}'" &

		# echo "relaying $1 to upload.providemedia.com" >>/tmp/ftp.log &
		# lftp -c "set ftp:ssl-allow no; set xfer:log 1; set xfer:log-file /tmp/lftp_providemedia.log; open -u YourDegreeHelper_796,@DUG#8Zd,]pf\`d}\\\\\\\"(\\\"/ upload.providemedia.com; put -O / '/tmp/${OUT_FILENAME}'" &

		echo "relaying $1 to ftp.higheredgrowth.com (Path 56 Media)" >>/tmp/ftp.log &
		lftp -c "set ftp:ssl-allow yes; set ssl:verify-certificate false; set ftp:ssl-protect-data true; set xfer:log 1; set xfer:log-file /tmp/lftp_highered_path56.log; open -u \"Path 56 Media\",E(bPr-TYg55,uL2* ftp.higheredgrowth.com; put -O / '/tmp/${OUT_FILENAME}'" &


		# PROVIDE MEDIA
		echo "relaying $1 to new YDH Providemedia ftp.higheredgrowth.com (your_degree_helper_allied_796)" >>/tmp/ftp.log &
		do_ftp \
			$1 \                              # Input file                                   
			your_degree_helper_allied_796 \   # Username                      
			'phtcMJDChQ4)?o7\' \              # Password (single quoted, escape single quotes with '\''            
			upload.providemedia.com \         # Hostname                         
			'/' \                             # Destination path     
			/tmp/lftp_providemedia.log \      # Log file            
			"${call}.wav" \                   # Destination filename       
			"set ftp:ssl-allow no;" &         # FTP Server options     

		# DAY PACER
		echo "relaying $1 to new leadhoop daypacer (daypacer_school_search_29)" >>/tmp/ftp.log &
		do_ftp \
			$1 \
			daypacer_school_search_29 \
			'>oY]U=yc'\''?Ks2;69' \
			upload.leadhoop.com \
			'/' \
			/tmp/lftp_leadhoop_daypacer.log \
			"${call}.wav" \
			"set ftp:ssl-allow yes; set ssl:verify-certificate false;" &

		# PATH56
		echo "relaying $1 to upload.leadhoop.com (path 56)" >>/tmp/ftp.log &
		do_ftp \
			$1 \
			path56_college_review_26 \
			'i&s+EC6FJL$=`Au5' \
			upload.leadhoop.com \
			'/' \
			/tmp/lftp_leadhoop_path56.log \
			"${call}.wav" \
			"set ftp:ssl-allow yes; set ssl:verify-certificate false;"

		rm /tmp/${OUT_FILENAME}
	else
		echo "Not sending to ftp destinations (ftp out set to false)" >>/tmp/ftp.log
	fi

	echo "moving $FILESPEC to /data/uploaded/$filename" >>/tmp/s3.log
	mv "$FILESPEC" "/data/uploaded/$filename"

	if ([ $2 = true ]); then
		output="s3://${S3_BUCKET}/Recordings/$year/$month/$day/$campaign/$filename"
		echo "moving /data/uploaded/$filename to $output" >>/tmp/s3.log
		${AWS_CLI} s3 cp "/data/uploaded/$filename" "$output" --no-progress >>/tmp/s3.log
	fi

	output="s3://${S3_BUCKET_ALL}/Recordings/$year/$month/$day/$campaign/$filename"
	echo "moving /data/uploaded/$filename to $output" >>/tmp/s3.log
	${AWS_CLI} s3 cp "/data/uploaded/$filename" "$output" --no-progress >>/tmp/s3.log
fi

echo "" >>/tmp/ftp.log

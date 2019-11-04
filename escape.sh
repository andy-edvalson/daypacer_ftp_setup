#!/bin/bash


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

## 
set -x
do_ftp \
    /tmp/test.txt \
    your_degree_helper_allied_796 \
    'phtcMJDChQ4)?o7\' \
    upload.providemedia.com \
    '/' \
    /tmp/lftp_providemedia_new.log \
    "test.text" \
    "set ftp:ssl-allow no;" &

do_ftp \
    /tmp/test.txt \
    daypacer_school_search_29 \
    '>oY]U=yc'\''?Ks2;69' \
    upload.leadhoop.com \
    '/' \
    /tmp/lftp_providemedia_new.log \
    "test.text" \
    "set ftp:ssl-allow yes; set ssl:verify-certificate false;" &

do_ftp \
    /tmp/test.txt \
    path56_college_review_26 \
    'i&s+EC6FJL$=`Au5' \
    upload.leadhoop.com \
    '/' \
    /tmp/lftp_providemedia_new.log \
    "test.text" \
    "set ftp:ssl-allow yes; set ssl:verify-certificate false;"

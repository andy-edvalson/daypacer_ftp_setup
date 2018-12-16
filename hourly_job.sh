#!/bin/bash
set -v

declare AWS_CLI='/usr/local/bin/aws'
declare S3_LOGS='/var/log/s3.log'

declare REGEX="([a-z\/]+)?((recording\.)?([0-9]{10}|Unavailable)_?([0-9]{10}|Unavailable)?_([0-9A-Z]+)_([a-zA-Z0-9\@\._]+.[com|net|org])_([a-zA-Z0-9\ \_\-]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare OUT_PATH="/data/staging"
declare IN_PATH="/data/recordings"
declare MINUTE_DELAY=60

declare CNS_REGEX="([a-z\/]+)CNS_([0-9-]+)_([0-9:\ AMP]+)_([0-9]+).wav"  # 1: Path  2: Date  3: Time  4: Phone
declare CNS_S3_BUCKET="cns-recordings"

if [ ! -d $OUT_PATH ]
then
  echo "Creating: $OUT_PATH"
  mkdir $OUT_PATH
fi

# store a temp copy of all files just to be safe for now
cp ${IN_PATH}/* /data/orig

# find all wav files older than an hour
find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | while read f
do

  # if file still exists
  if [[ -f $f ]]
  then

    if [[ $f =~ $CNS_REGEX ]]
    then
      output="s3://${CNS_S3_BUCKET}"
      echo "moving $f to $output" >> ${S3_LOGS}
      ${AWS_CLI} s3 mv "$f" "$output" >> ${S3_LOGS}
      continue
    fi

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

      echo $f >> /tmp/stitch.log
      echo ${call}
      count=`find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | grep ${call} | wc -l`
      if (( ${count} > 1 ))
      then
        # multipart call
        echo "${count} files found in call ${call}, merging files to staging dir" >> /tmp/stitch.log
        IFS=$'\n'
	set -v
        ls -tr ${IN_PATH} | grep ${call} >> /tmp/stitch.log
        cd ${IN_PATH} && sox $(ls -tr ${IN_PATH} | grep ${call}) "${OUT_PATH}/${phone}_${ani}_${call}_${email}_${campaign}_${month}_${day}_${year}_${hour}_${minute}_${second} ${period}.wav"
	rm $(find ${IN_PATH} -name "*.wav" -type f | grep ${call})
      else
        # single part call
        echo "Single call for call ${call}, moving file to staging dir" >> /tmp/stitch.log
        mv "$f" ${OUT_PATH}
      fi
    fi
  fi
done

# sleep for a few seconds to wait for copies to finish
echo "Files have been parsed and staged, sleeping for a few seconds to wait for transfers to finish"
sleep 5

# upload output from job
find ${OUT_PATH} -name "*.wav" -type f -mmin +0 | while read f
do
  # if file still exists
  if [[ -f $f ]]
  then
    echo "call do_upload on ${f}" >> /tmp/stitch.log
    /usr/local/bin/do_upload.sh "$f" >> /tmp/do_upload.log 2>&1
  fi
done

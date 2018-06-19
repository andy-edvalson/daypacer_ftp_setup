#!/bin/bash
set -v

declare REGEX="([a-z\/])+((recording\.)?([0-9a-zA-Z]*)_([0-9A-Z]+)_([a-zA-Z0-9\@\.]+)_([a-zA-Z0-9\ \_]+)_([0-9]+)_([0-9]+)_([0-9]+)(_([0-9]+)_([0-9]+)_([0-9]+) ([APM]+))?.wav)"
declare OUT_PATH="/data/staging"
declare IN_PATH="/data/recordings"
declare MINUTE_DELAY=60

if [ ! -d $OUT_PATH ]
then
  echo "Creating: $OUT_PATH"
  mkdir $OUT_PATH
fi

# store a temp copy of all files just to be safe for now
# cp ${IN_PATH}/* /tmp/orig

# find all wav files older than an hour
find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | while read f
do

  # if file still exists
  if [[ -f $f ]]
  then

      # ... loop body
    if [[ $f =~ $REGEX ]]
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

  echo $f
      echo ${call}

      count=`find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | grep ${call} | wc -l`
      if (( ${count} > 1 ))
      then
        echo "${count} files found in call ${call}, merging files to staging dir"
        IFS=$'\n'
	set -v
find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | grep ${call} | sort -n
        sox $(find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | grep ${call} | sort -n) "${OUT_PATH}/recording.${phone}_${call}_${email}_${campaign}_${month}_${day}_${year}_${hour}_${minute}_${second} ${period}.wav"
        rm $(find ${IN_PATH} -name "*.wav" -type f -mmin +${MINUTE_DELAY} | grep ${call})
      else
        echo "Single call for call ${call}, moving file to staging dir"
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
    echo "call do_upload on ${f}"
    /usr/local/bin/do_upload.sh "$f"
  fi
done

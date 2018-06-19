#!/bin/bash

declare OUT_PATH=/data/staging

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

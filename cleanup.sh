#!/bin/bash

find /home/ftpusers/recordings -name "*.wav" | while read f
do
    # ... loop body

    echo $f
    /usr/local/bin/upload_script.sh "$f"
done

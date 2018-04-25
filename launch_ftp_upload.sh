#!/bin/bash

if ps -ef | grep -v grep | grep pure-upload; then
        exit 0
else
        echo "launching pure-upload"
	sudo pure-uploadscript -B -r /usr/local/bin/upload_script.sh
        exit 0
fi

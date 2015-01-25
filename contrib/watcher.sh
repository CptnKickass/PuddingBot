#!/usr/bin/env bash

# This script operates outside of normal parameters, and therefore is not included
# in the modules directory. It's activated by splitbrain's "watcher" script, and works
# by directly injecting messages into pudding. Because it requires manual setup, it 
# requires manual set up and enabling. IF YOU DO NOT KNOW WHAT THIS DOES, DO NOT USE IT!
# splitbrain's python watcher script: https://github.com/splitbrain/Watcher

## Config
# Parse the input as appropriate for you. It should be passed as a full path.
input="${@#*public_html/}"
# Where to output the message?
output="/home/goose/PuddingBot/var/outbound"
# What channel(s) to send the message to?
chan=("#goose")

## Source
# Ignore swap files
inputChk="${input##*/}"
if echo "$inputChk" | egrep -q "(^\.|FRAPSBMP\.TMP$)"; then
	exit 0
fi

if echo "${input}" | fgrep -q " "; then
	mv "/home/goose/public_html/${input}" "/home/goose/public_html/${input// /_}" 
	input="${input// /_}"
fi

input="https://${input}"

if [ -e "$output" ]; then
	for i in "${chan[@]}"; do
		echo "PRIVMSG ${i} :[WATCHER] File Created: $input" >> "$output"
	done
fi

exit 0

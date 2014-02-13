#!/usr/bin/env bash

# This script operates outside of normal parameters, and therefore is not included
# in the modules directory. It's activated by splitbrain's "watcher" script, and works
# by directly injecting messages into pudding. Because it requires manual setup, it 
# requires manual set up and enabling. IF YOU DO NOT KNOW WHAT THIS DOES, DO NOT USE IT!
# splitbrain's python watcher script: https://github.com/splitbrain/Watcher

## Config
# Parse the input as appropriate for you
input="${1#*public_html/}"
# Where to output the message?
output=""
# What channel(s) to send the message to?
chan=("#FoxDen")

## Source
if [ "$(echo "$input" | egrep -c "(\.sw(p|x|px)$)")" -eq "1" ]; then
	exit 0
fi

input="https://${input}"

if [ -e "$output" ]; then
	for i in "${chan[@]}"; do
		echo "PRIVMSG ${1} :[WEB] File Created: $input" >> "$output"
	done
fi

exit 0

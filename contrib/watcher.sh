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
if [[ "$1" == "--dep-check" ]]; then
	echo "Dependency check failed: This module is not meant to be loaded into the bot!"
	exit 255
fi

# Ignore swap files
inputChk="${input##*/}"
if egrep -q "(^\.|FRAPSBMP\.TMP$|4913$)" <<<"${inputChk}"; then
	exit 0
fi

if fgrep -q " " <<<"${input}"; then
	mv "/home/goose/public_html/${input}" "/home/goose/public_html/${input// /_}" 
	input="${input// /_}"
fi

input="https://${input}"

if [[ -e "${output}" ]] && ! [[ -e "${output%/*}/.silence" ]] && ! [[ -e "${output%/*}/.silence1" ]]; then
	for i in "${chan[@]}"; do
		echo "PRIVMSG ${i} :[WATCHER] File Created: ${input}" >> "${output}"
	done
fi

exit 0

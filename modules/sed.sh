#!/usr/bin/env bash

## Config
# Config options go here

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "$depFail" -eq "1" ]; then
			exit 1
		else
			echo "ok"
			exit 0
		fi
	else
		echo "ok"
		exit 0
	fi
fi

# Hook should either be "Prefix" or "Format". Prefix will patch whatever
# the $comPrefix is, i.e. !command. Format will match a message specific
# format, i.e. the sed module.
modHook="Prefix"

# If the $modHook is "Format", what format should the message match to
# catch the script? This should be a regular expression pattern, mathing
# a regular channel PRIVMSG following the colon (It won't match a /ME)
# For example, if you wanted to match:
#  :goose!goose@goose PRIVMSG #GooseDen :s/foo/bar/
# Your $modForm would be:
#  modForm="^s/.+/.+/"
# Leave blank if you don't need this
modForm=""

# If you need your modForm to be case insensitive, and yes. If not, answer
# no. If you don't need this, leave it blank.
modFormCase=""

# A one liner on how to use the module/what it does
modHelp="This module provides examples on how to write other modules"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@

						elif [ "$isSed" -eq "1" ]; then
							sedCom="$(echo "$message" | egrep -o -i "s\/.*\/.*\/(i|g|ig)?")"
							sedItem="${sedCom#s/}"
							sedItem="${sedItem%/*/*}"
							prevLine="$(fgrep "PRIVMSG" "${input}" | fgrep "${sedItem}" | tail -n 2 | head -n 1)"
							prevSend="$(echo "$prevLine" | awk '{print $1}' | sed "s/!.*//" | sed "s/^://")"
							line="$(read -r one two three rest <<<"${prevLine}"; echo "$rest" | sed "s/^://")"
							if [ -n "$line" ]; then
								lineFixed="$(echo "$line" | sed "${sedCom}")"
								echo "PRIVMSG $senderTarget :[FTFY] <${prevSend}> $lineFixed" >> $output
							fi

#!/usr/bin/env bash

## Config
# WolframAlpha API Key
wolfApi=""

## Source
if [ -e "var/.conf" ]; then
	source var/.conf
else
	nick="Null"
fi

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=("curl" "tr")
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
#  modForm=("^.*PRIVMSG.*:s/.+/.+/$")
# If the $modHook is "Prefix", what command word should trigger the module?
# This is an array, so you can set as many hooks as you need.
modForm=("example")

# If you need your modForm to be case insensitive, answer yes. If not, answer
# no. This only applies for messages trigged by "Format" mode.
# If you're using "Prefix" mode, you can leave this blank.
modFormCase=""

# A one liner on how to use the module/what it does
modHelp="This module provides examples on how to write other modules"
modFlag="m"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@
msg="$@"
# Color character used to start a category: [1;36m
# Color character used to end a category: [0m
if [ -z "${wolfApi}" ]; then
	echo "A Wolfram Alpha API key is required"
elif [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
else
	unset wolfArr
	wolfQ="$(read -r one two three four rest <<<"$msg"; echo "$rest")"
	# properly encode query
	wolfQ="$(echo "${wolfQ}" | sed 's/+/%2B/g' | tr '\ ' '\+')"
	# fetch and parse result
	result=$(curl -s "http://api.wolframalpha.com/v2/query?input=${wolfQ}&appid=${wolfApi}&format=plaintext")
	echo "Wolfram Alpha Results:"
	echo -e ${result} | tr '\n' '\t' | sed -e 's/<plaintext>/\'$'\n<plaintext>/g' | grep -oE "<plaintext>.*</plaintext>|<pod title=.[^\']*" | sed 's!<plaintext>!!g; s!</plaintext>!!g;  s!<pod title=.*!\\\x1b[1;36m&\\\x1b[0m!g; s!<pod title=.!!g; s!\&amp;!\&!' | tr '\t' '\n' | sed  '/^$/d; s/\ \ */\ /g' | while read line; do
		if [ "$(echo "$line" | egrep -c "$(echo -e "\e\[1;36m")")" -eq "1" ]; then
			# It's a category
			echo "${wolfArr[@]}"
			unset wolfArr
			line="$(echo "$line" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
			echo "${line}"
			sleep 1
		else
			# It's an answer
			wolfArr+=("$line")
		fi
	done
	echo "${wolfArr[@]}"
	unset wolfArr
fi
exit 0

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
#  modForm=("^.*PRIVMSG.*:s/.+/.+/$")
# If the $modHook is "Prefix", what command word should trigger the module?
# This is an array, so you can set as many hooks as you need.
modForm=("tell")

# If you need your modForm to be case insensitive, answer yes. If not, answer
# no. This only applies for messages trigged by "Format" mode.
# If you're using "Prefix" mode, you can leave this blank.
modFormCase=""

# A one liner on how to use the module/what it does
modHelp="Sometimes people need things told to them. This module assists in that."

# What flag should be required for the user to access this module? No
# error message will be sent if insufficient privs are found. This is
# where you can use the custom flags feature of admins.conf
modFlag="m"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@
msg="$@"
target="$(awk '{print $5}' <<<"$msg")"
# Format should be:
# :N!U@H PRIVMSG ${target} :!explain <to> ${target} <that> ${explain}
explain="$(read -r one two three four five rest <<<"$msg"; echo "$rest")"
re="you're"
explain="${explain//she\'s/$re}"
explain="${explain//he\'s/$re}"
explain="${explain//they\'re/$re}"
if [ -z "$target" ]; then
	echo "This command requires a target"
elif [ -z "$explain" ]; then
	echo "You didn't tell me what to say"
	echo "(Format is: !tell SnoFox he's a faggot)"
else
	echo "${target}: ${explain}"
fi
exit 0

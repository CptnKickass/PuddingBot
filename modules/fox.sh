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

			isFox="$(echo "$message" | fgrep -c -i "what does the fox say?")"
			if [ "$isFox" -eq "1" ]; then
				if [ -z "$foxResponseNum" ]; then
					foxResponseNum="1"
				elif [ "$foxResponseNum" -eq "14" ]; then
					foxResponseNum="1"
				fi
				case $foxResponseNum in
					1) foxResponse="Ring-ding-ding-ding-dingeringeding!";;
					2) foxResponse="Gering-ding-ding-ding-dingeringeding!";;
					3) foxResponse="Wa-pa-pa-pa-pa-pa-pow!";;
					4) foxResponse="Hatee-hatee-hatee-ho!";;
					5) foxResponse="Joff-tchoff-tchoffo-tchoffo-tchoff!";;
					6) foxResponse="Tchoff-tchoff-tchoffo-tchoffo-tchoff!";;
					7) foxResponse="Jacha-chacha-chacha-chow!";;
					8) foxResponse="Chacha-chacha-chacha-chow!";;
					9) foxResponse="Fraka-kaka-kaka-kaka-kow!";;
					10) foxResponse="A-hee-ahee ha-hee!";;
					11) foxResponse="Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!";;
					12) foxResponse="Bay-budabud-dum-bam!";;
					13) foxResponse="Abay-ba-da bum-bum bay-do!";;
				esac
				foxResponseNum="$(( $foxResponseNum + 1 ))"
				echo "PRIVMSG $senderTarget :${foxResponse}" >> $output
			fi

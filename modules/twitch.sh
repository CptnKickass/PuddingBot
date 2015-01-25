#!/usr/bin/env bash

## Config
usersDir="/home/goose/PuddingBot/users"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=("curl" "mktemp" "fgrep")
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

modHook="Prefix"
modForm=("twitch")
modFormCase=""
modHelp="Checks to see who's streaming on twitch.tv"
modFlag="m"

if [ ! -d "${usersDir}" ]; then
	echo "Users directory in config does not appear to exist."
	exit 255
fi

numOnline="0"
numReg="$(fgrep -c "meta=\"twitchuser=" "${usersDir}"/*.conf)"
if [ "$numReg" -eq "0" ]; then
	echo "No registered Twitch.tv users online."
else
	for match in "$(fgrep "meta=\"twitchuser=" "${usersDir}/"*.conf /dev/null)"; do
		twitchUser="${match#*.conf:meta=\"twitchuser=}"
		twitchUser="${twitchUser%\"}"
		puddingUserFile="${match%%:meta=\"twitchuser=*}"
		apiCall="$(curl -s "https://api.twitch.tv/kraken/streams/${twitchUser}")"
		if [ "$(echo "${apiCall}" | fgrep -c "\"stream\":null")" -ne "1" ]; then
			numOnline="$(( $numOnline + 1 ))"
			streamContent="${apiCall#*\"game\":\"}"
			streamContent="${streamContent%%\"*}"
			puddingUser="$(egrep -v "^#" "${puddingUserFile}" | fgrep "user=\"")"
			puddingUser="${puddingUser#user=\"}"
			puddingUser="${puddingUser%\"}"
			echo "${puddingUser} is currently streaming ${streamContent} at http://www.twitch.tv/${twitchUser}"
		fi
	done
fi
if [ "$numOnline" -eq "0" ]; then
	echo "No registered Twitch.tv users online."
fi

exit 0

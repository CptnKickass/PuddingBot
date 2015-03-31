#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "mktemp" "fgrep")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
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

if [[ -e "var/.conf" ]]; then
	source var/.conf
else
	echo -e "Unable to locate \"${red}\${input}${reset}\" file! (Is bot running?) Exiting."
	exit 1
fi


modHook="Prefix"
modForm=("twitch")
modFormCase=""
modHelp="Checks to see who's streaming on twitch.tv. You can register your twitch username to work with this module via the command: \"set meta twitchuser=YOUR-TWITCH-USERNAME-HERE\""
modFlag="m"

if [[ ! -d "${userDir}" ]]; then
	echo "Users directory in config does not appear to exist."
	exit 255
fi

numOnline="0"
numReg="0"
if ! egrep -q "^meta=\"twitchuser=" ${userDir}/*.conf; then
	echo "No registered Twitch.tv users online."
else
	for match in $(fgrep "meta=\"twitchuser=" "${userDir}/"*.conf /dev/null); do
		unset twitchUser
		unset puddingUserFile
		unset apiCall
		twitchUser="${match#*.conf:meta=\"twitchuser=}"
		twitchUser="${twitchUser%\"}"
		puddingUserFile="${match%%:meta=\"twitchuser=*}"
		apiCall="$(curl -s "https://api.twitch.tv/kraken/streams/${twitchUser}")"
		if [[ "$(fgrep -c "\"stream\":null" <<<"${apiCall}")" -ne "1" ]]; then
			numOnline="$(( ${numOnline} + 1 ))"
			streamContent="${apiCall#*\"game\":\"}"
			streamContent="${streamContent%%\"*}"
			puddingUser="$(egrep -v "^#" "${puddingUserFile}" | fgrep "user=\"")"
			puddingUser="${puddingUser#user=\"}"
			puddingUser="${puddingUser%\"}"
			echo "${puddingUser} is currently streaming ${streamContent} at http://www.twitch.tv/${twitchUser}"
		fi
	done
fi
if [[ "${numOnline}" -eq "0" ]]; then
	echo "No registered Twitch.tv users online."
fi

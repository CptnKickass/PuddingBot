#!/usr/bin/env bash

## Config
# None

## Source
if [ -e "var/.conf" ]; then
	source var/.conf
else
	nick="Null"
fi

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl")
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "${depFail}" -eq "1" ]; then
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
modForm=("isup")
modFormCase=""
modHelp="Checks a site for up/down status via http://isup.me/"
modFlag="m"
siteToCheck="${msgArr[4]}"
if [ -z "${siteToCheck}" ]; then
	echo "This command requires a parameter"
elif ! egrep -q "(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}" <<<"${siteToCheck}"; then
	echo "The domain ${siteToCheck} does not appear to be a valid domain"
elif [ "$(egrep -c "(www\.)?(isup\.me|downforeveryoneorjustme\.com)/?" <<<"${siteToCheck}")" -eq "1" ]; then
	echo "Error: Apocalypse detected. Purging of humanity imminent."
else
	siteToCheck="${msgArr[4]#http://}"
	siteToCheck="${siteToCheck#https://}"
	isSiteUp="$(curl -A "${nick}" -m 5 -k -s -L "http://isup.me/${siteToCheck}" | fgrep -c "It's just you.")"
	# 1 means it's up, 0 means it's down
	if [ "${isSiteUp}" -eq "1" ]; then
		echo "${siteToCheck} is UP, according to http://isup.me/"
	elif [ "${isSiteUp}" -eq "0" ]; then
		echo "${siteToCheck} is DOWN, according to http://isup.me/"
	else
		echo "You should never get this message. Is http://isup.me/ down?"
	fi
fi
exit 0

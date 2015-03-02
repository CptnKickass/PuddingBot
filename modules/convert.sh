#!/usr/bin/env bash

## Config
# Credit for conversions to convert.net
# API available at: http://www.convert.net/api.php

# Convert.net API user ID
convUid=""
# Convert.net Developer Token ID
convTid=""

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m")
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
modForm=("convert")
modFormCase=""
modHelp="Uses convert.net API to convert things"
modFlag="m"
msg="$@"
if [ -z "$convUid" ]; then
	echo "A convert.net API user ID is required"
elif [ -z "$convTid" ]; then
	echo "A convert.net developer token ID is required"
elif [ -z "$(awk '{print $5}' <<<"${msg}")" ]; then
	echo "This command requires a parameter"
else
	searchTerm="$(read -r one two thee four rest <<<"$msg"; echo "$rest")"
	searchResult="$(curl -m 5 -s --data-urlencode "expression=${searchTerm}" "http://www.stands4.com/services/v2/conv.php?uid=${convUid}&tokenid=${convTid}")"
	returnCode="$(fgrep "<errorCode>" <<<"$searchResult")"
	returnCode="${returnCode#*<errorCode>}"
	returnCode="${returnCode%</errorCode>*}"
	if [ "$returnCode" -eq "0" ]; then
		result="$(fgrep "<result>" <<<"$searchResult")"
		result="${result#*<result>}"
		result="${result%</result>*}"
		result="${result//&amp;deg;/°}"
		echo "$result"
	else
		errorMessage="$(fgrep "<errorMessage>" <<<"$searchResult")"
		errorMessage="${errorMessage#*<errorMessage>}"
		errorMessage="${errorMessage%</errorMessage>*}"
		echo "Unable to obtain conversion (Convert.net returned error code ${returnCode}, and error message ${errorMessage})"
	fi
fi
exit 0

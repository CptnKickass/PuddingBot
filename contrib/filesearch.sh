#!/usr/bin/env bash

## Config
# Path to search for file
searchPath="/mnt/storage/goose/public_html/captain-kickass.net"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("find")
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
modForm=("find" "search")
modFormCase=""
modHelp="Searches for files in a path and modifies them to a valid URL"
modFlag="m"
msg="$@"
if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
else
	searchItem="$(read -r one two three four rest <<<"$msg"; echo "$rest")"
	results="$(find "${searchPath}" -iname "${searchItem}")"
	resultsNum="$(echo "$results" | wc -l)"
	if [  -z "$results" ]; then
		echo "No results found"
	elif [ "$resultsNum" -gt "10" ]; then
		echo "More than 10 results returned. Not printing to prevent spam."
	else
		echo "$results" | while read line; do
			item="${line#*public_html/}"
			item="https://${item}"
			echo "${item}"
		done
	fi
fi
exit 0

#!/usr/bin/env bash

# This will eventually be the working wikipedia module. It's still non-functional right now.

## Config

## Source

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
modForm=("wiki")
modFormCase=""
modHelp="Searches wikipedia for a query and returns the first result"
modFlag="m"
msg="$@"
if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
else
	searchTerm="$(read -r one two thee four rest <<<"$msg"; echo "$rest")"
	result="$(curl -s --data-urlencode "titles=${searchTerm}" "http://en.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exsentences=10&rawcontinue=&")"
	if [ -n "$result" ]; then
		echo "$result"
	else
		echo "No results founds"
	fi
fi
exit 0

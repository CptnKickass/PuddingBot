#!/usr/bin/env bash

## Config
# Google API key
googleApi=""
# Custom Search Engine ID
googleCid=""

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
modForm=("google")
modFormCase=""
modHelp="Searches google for a query and returns the first result"
modFlag="m"
msg="$@"
if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
else
	searchTerm="$(read -r one two thee four rest <<<"$msg"; echo "$rest")"
	searchResult="$(curl -s --get --data-urlencode "q=${searchTerm}" --data-urlencode "cx=${googleCid}" "https://www.googleapis.com/customsearch/v1?key=${googleApi}&num=1")"
	results="$(grep -m 1 "totalResults" <<<"$searchResult")"
	results="${results#*\": \"}"
	results="${results%%\"*}"
	if [ "$results" -ne "0" ]; then
		link="$(grep "\"link\"" <<<"$searchResult" | tail -n 1)"
		link="${link#*\": \"}"
		link="${link%%\"*}"
		title="$(grep "\"title\"" <<<"$searchResult" | tail -n 1)"
		title="${title#*\": \"}"
		title="${title%%\"*}"
		echo "${link} - ${title}"
	else
		echo "No results founds"
	fi
fi
exit 0

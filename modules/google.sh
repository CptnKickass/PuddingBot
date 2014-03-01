#!/usr/bin/env bash

## Config
# None

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
	searchResult="$(curl -s --get --data-urlencode "q=${searchTerm}" http://ajax.googleapis.com/ajax/services/search/web?v=1.0 | sed 's/"unescapedUrl":"\([^"]*\).*/\1/;s/.*GwebSearch",//')"
	if echo "$searchResult" | fgrep -q "\"responseDetails\": null,"; then
		echo "No results found"
	else
		echo "${searchResult}"
	fi
fi
exit 0

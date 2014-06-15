#!/usr/bin/env bash

## Config
# None

## Source
# I need to fix this module
echo "THIS MODULE IS BROKEN AND SHOULD NOT BE USED UNTIL UNBROKEN IN A FUTURE UPDATE!"
exit 255

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
modForm=("wiki" "wikipedia")
modFormCase=""
modHelp="Searches Wikipedia for a topic"
modFlag="m"
msg="$@"
if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
else
	searchTerm="$(read -r one two thee four rest <<<"$msg"; echo "$rest")"
	searchResult="$(curl -s --get --data-urlencode "q=${searchTerm} site:en.wikipedia.org" http://ajax.googleapis.com/ajax/services/search/web?v=1.0 | sed 's/"unescapedUrl":"\([^"]*\).*/\1/;s/.*GwebSearch",//')"
	if [ "$(echo "$searchResult" | fgrep -c "\"responseDetails\": null,")" -eq "1" ]; then
		echo "[Wiki] No results found"
	else
		echo "[Wiki] ${searchResult}"
	fi
fi
exit 0

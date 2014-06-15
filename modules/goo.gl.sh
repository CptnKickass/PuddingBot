#!/usr/bin/env bash

## Config
# goo.gl API key
googleApi=""

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
modForm=("short" "shorten")
modFormCase=""
modHelp="Shortens a URL via Google's URL shortener service"
modFlag="m"
msg="$@"
if [ -z "${googleApi}" ]; then
	echo "A Google API key is required"
elif [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	shortItem="$(fgrep "PRIVMSG" "${input}" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | tail -n 1)"
	if [ -n "$shortItem" ]; then
		echo "Shortening most recently spoken URL (${shortItem})"
		shortUrl="$(curl -A "$nick" -m 5 -k -s -L -H "Content-Type: application/json" -d "{\"longUrl\": \"${shortItem}\"}" "https://www.googleapis.com/urlshortener/v1/url?key=${googleApi}" | fgrep "\"id\"" | egrep -o "http(s)?://goo.gl/[A-Z|a-z|0-9]+")"
		echo "Shortened URL: ${shortUrl}"
	else
		echo "No URL to shorten provided, and no recently spoken URL's in my memory."
	fi
elif ! echo "$msg" | awk '{print $5}' | egrep -q "http(s?):\/\/[^ \"\(\)\<\>]*"; then
	echo "This does not appear to be a valid URL"
else
	shortItem="$(echo "$msg" | awk '{print $5}')"
	shortUrl="$(curl -A "$nick" -m 5 -k -s -L -H "Content-Type: application/json" -d "{\"longUrl\": \"${shortItem}\"}" "https://www.googleapis.com/urlshortener/v1/url?key=${googleApi}" | fgrep "\"id\"" | egrep -o "http(s)?://goo.gl/[A-Z|a-z|0-9]+")"
	echo "Shortened URL: ${shortUrl}"
fi
exit 0

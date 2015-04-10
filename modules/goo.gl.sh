#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=("gooGlApiKey")
	if [[ "${#apis[@]}" -ne "0" ]]; then
		if [[ -e "api.conf" ]]; then
			for i in "${apis[@]}"; do
				val="$(egrep "^${i}" "api.conf")"
				val="${val#${i}=\"}"
				val="${val%\"}"
				if [[ -z "${val}" ]]; then
					echo -e "Missing api key \"${red}${i}${reset}\"! Exiting."
					apiFail="1"
				fi
			done
		else
			path="$(pwd)"
			path="${path##*/}"
			path="./${path}/${0##*/}"
			echo "Unable to locate \"api.conf\"!"
			echo "(Are you running the dependency check from the main directory?)"
			echo "(ex: ${path} --dep-check)"
			exit 255
		fi
	fi
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

if [[ -e "var/.conf" ]]; then
	source var/.conf
else
	nick="Null"
fi

modHook="Prefix"
modForm=("short" "shorten")
modFormCase=""
modHelp="Shortens a URL via Google's URL shortener service"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	shortItem="$(fgrep "PRIVMSG" "${input}" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | tail -n 1)"
	if [[ -n "${shortItem}" ]]; then
		echo "[Goo.gl] Shortening most recently spoken URL (${shortItem})"
		shortUrl="$(curl -A "${nick}" -m 5 -k -s -L -H "Content-Type: application/json" -d "{\"longUrl\": \"${shortItem}\"}" "https://www.googleapis.com/urlshortener/v1/url?key=${gooGlApiKey}" | fgrep "\"id\"" | egrep -o "http(s)?://goo.gl/[A-Z|a-z|0-9]+")"
		echo "[Goo.gl] Shortened URL: ${shortUrl}"
	else
		echo "[Goo.gl] No URL to shorten provided, and no recently spoken URL's in my memory."
	fi
elif ! egrep -q "http(s?):\/\/[^ \"\(\)\<\>]*" <<<"${msgArr[4]}"; then
	echo "[Goo.gl] This does not appear to be a valid URL"
else
	shortItem="${msgArr[4]}"
	shortUrl="$(curl -A "${nick}" -m 5 -k -s -L -H "Content-Type: application/json" -d "{\"longUrl\": \"${shortItem}\"}" "https://www.googleapis.com/urlshortener/v1/url?key=${gooGlApiKey}" | fgrep "\"id\"" | egrep -o "http(s)?://goo.gl/[A-Z|a-z|0-9]+")"
	echo "[Goo.gl] Shortened URL: ${shortUrl}"
fi

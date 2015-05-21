#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=()
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
modForm=("isup")
modFormCase=""
modHelp="Checks a site for up/down status via http://isup.me/"
modFlag="m"
siteToCheck="${msgArr[4]}"
if [[ -z "${siteToCheck}" ]]; then
	echo "[IsUp] This command requires a parameter"
elif egrep -qi "(www\.)?(isup\.me|downforeveryoneorjustme\.com)/?" <<<"${siteToCheck}"; then
	echo "Error: Apocalypse detected. Purging of humanity imminent."
elif egrep -qi "localhost" <<<"${siteToCheck}"; then
	echo "ACTION has quit IRC (Connection reset by peer)"
elif ! egrep -q "(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}" <<<"${siteToCheck}"; then
	echo "[IsUp] The domain ${siteToCheck} does not appear to be a valid domain"
else
	siteToCheck="${msgArr[4]#http://}"
	siteToCheck="${siteToCheck#https://}"
	isSiteUp="$(curl -A "${nick}" -m 5 -k -s -L "http://isup.me/${siteToCheck}" | fgrep -c "It's just you.")"
	# 1 means it's up, 0 means it's down
	if [[ "${isSiteUp}" -eq "1" ]]; then
		echo "[IsUp] ${siteToCheck} is UP, according to http://isup.me/"
	elif [[ "${isSiteUp}" -eq "0" ]]; then
		echo "[IsUp] ${siteToCheck} is DOWN, according to http://isup.me/"
	else
		echo "[IsUp] You should never get this message. Is http://isup.me/ down?"
	fi
fi

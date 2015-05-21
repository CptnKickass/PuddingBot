#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("whois")
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

modHook="Prefix"
modForm=("whois" "available" "domain")
modFormCase=""
modHelp="Checks a domain for ownership availability (If a domain is registered or not)"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "[Whois] This command requires a parameter"
else
	domain="${msgArr[4]}"
	whois="$(whois "${domain}" | egrep -c "^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri")"
	if [[ "${whois}" -eq "0" ]]; then 
		echo "[Whois] ${domain} IS registered (Domain not available)"
	else
		echo "[Whois] ${domain} is NOT registered (Domain available)"
	fi 
fi

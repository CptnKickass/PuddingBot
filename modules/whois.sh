#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("whois")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
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
modForm=("whois" "available" "domain")
modFormCase=""
modHelp="Checks a domain for ownership availability (If a domain is registered or not)"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	domain="${msgArr[4]}"
	whois="$(whois "${domain}" | egrep -c "^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri")"
	if [[ "${whois}" -eq "0" ]]; then 
		echo "${domain} IS registered (Domain not available)"
	else
		echo "${domain} is NOT registered (Domain available)"
	fi 
fi

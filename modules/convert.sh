#!/usr/bin/env bash

# Credit for conversions to convert.net
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=("convApiKey" "convApiKeyToken")
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
modForm=("convert")
modFormCase=""
modHelp="Uses convert.net API to convert things"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "[Convert] This command requires a parameter"
else
	searchResult="$(curl -m 5 -s --data-urlencode "expression=${msgArr[@]:4}" "http://www.stands4.com/services/v2/conv.php?uid=${convApiKey}&tokenid=${convApiKeyToken}")"
	returnCode="$(fgrep "<errorCode>" <<<"${searchResult}")"
	returnCode="${returnCode#*<errorCode>}"
	returnCode="${returnCode%</errorCode>*}"
	if [[ "${returnCode}" -eq "0" ]]; then
		result="$(fgrep "<result>" <<<"${searchResult}")"
		result="${result#*<result>}"
		result="${result%</result>*}"
		result="${result//&amp;deg;/°}"
		echo "[Convert] ${result}"
	else
		errorMessage="$(fgrep "<errorMessage>" <<<"${searchResult}")"
		errorMessage="${errorMessage#*<errorMessage>}"
		errorMessage="${errorMessage%</errorMessage>*}"
		echo "[Convert] Unable to obtain conversion (Convert.net returned error code ${returnCode}, and error message ${errorMessage})"
	fi
fi

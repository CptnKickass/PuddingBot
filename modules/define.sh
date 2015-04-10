#!/usr/bin/env bash

# Credit for conversions to definitions.net

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
	apis=("defApiKey" "defApiKeyToken")
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
modForm=("def" "define")
modFormCase=""
modHelp="Uses definitions.net API to define things"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "[Define] This command requires a parameter"
else
	searchResult="$(curl -m 5 -s --get --data-urlencode "word=${msgArr[@]:4}" "http://www.stands4.com/services/v2/defs.php?uid=${defApiKey}&tokenid=${defApiKeyToken}")"
	returnCode="$(fgrep -c "<error>" <<<"${searchResult}")"
	if [[ "${returnCode}" -eq "0" ]]; then
		result="$(fgrep "<result>" <<<"${searchResult}")"
		result="${result#*<result>}"
		result="${result%%</result>*}"
		# At this point, ${result} is broken down to:
		# <term>material, stuff</term><definition>the tangible substance that goes into the makeup of a physical object</definition><example>"coal is a hard black material"; "wheat is the stuff they use to make bread"</example><partofspeech>noun</partofspeech>
		term="${result#*<term>}"
		term="${term%%</term>*}"
		def="${result#*<definition>}"
		def="${def%%</definition>*}"
		ex="${result#*<example>}"
		ex="${ex%%</example>*}"
		pos="${result#*<partofspeech>}"
		pos="${pos%%</partofspeech>*}"
		if [[ -n "${def}" ]]; then
			if [[ -n "${pos}" ]] && [[ -n "${example}" ]]; then
				echo "${term} (${pos}) - ${def} - Example: ${ex}"
			elif [[ -n "${pos}" ]] && [[ -z "${example}" ]]; then
				echo "${term} (${pos}) - ${def}"
			elif [[ -z "${pos}" ]] && [[ -n "${example}" ]]; then
				echo "${term} - ${def} - Example: ${ex}"
			else
				echo "${term} - ${def}"
			fi
		else
			echo "[Define] No definition found"
		fi
	else
		errorMessage="$(fgrep "<errorMessage>" <<<"${searchResult}")"
		errorMessage="${errorMessage#*<errorMessage>}"
		errorMessage="${errorMessage%</errorMessage>*}"
		echo "[Define] Unable to obtain conversion (Definitions.net returned error code ${returnCode}, and error message ${errorMessage})"
	fi
fi

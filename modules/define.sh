#!/usr/bin/env bash

## Config
# Credit for conversions to definitions.net
# API available at: http://www.definitions.net/api.php

# Definitions.net API user ID
apiKey=""
# Definitions.net Developer Token ID
apiKeyToken=""

## Source

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m")
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
modForm=("def" "define")
modFormCase=""
modHelp="Uses definitions.net API to define things"
modFlag="m"
if [[ -z "${apiKey}" ]]; then
	echo "A definitions.net API user ID is required"
elif [[ -z "${apiKeyToken}" ]]; then
	echo "A definitions.net developer token ID is required"
elif [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	searchResult="$(curl -m 5 -s --get --data-urlencode "word=${msgArr[@]:4}" "http://www.stands4.com/services/v2/defs.php?uid=${apiKey}&tokenid=${apiKeyToken}")"
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
			echo "No definition found"
		fi
	else
		errorMessage="$(fgrep "<errorMessage>" <<<"${searchResult}")"
		errorMessage="${errorMessage#*<errorMessage>}"
		errorMessage="${errorMessage%</errorMessage>*}"
		echo "Unable to obtain conversion (Definitions.net returned error code ${returnCode}, and error message ${errorMessage})"
	fi
fi
exit 0

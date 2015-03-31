#!/usr/bin/env bash

## Config
# Path to search for file
searchPath="/home/goose/PuddingBot"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("find")
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
modForm=("src" "source")
modFormCase=""
modHelp="Displays a relevant source file on github"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	readarray -t results <<<"$(find "${searchPath}" -not -path "${searchPath}/.git/*" -not -path "${searchPath}/var/*" -iname "${msgArr[@]:4}")" 
	if [[ -z "${results[*]}" ]]; then
		echo "No results found"
	elif [[ "${#results[@]}" -gt "10" ]]; then
		echo "More than 10 results returned. Not printing to prevent spam."
	else
		for line in "${results[@]}"; do
			item="${line#*${searchPath}/}"
			if ! fgrep -q "${item}" "${searchPath}/.gitignore}"; then
				item="https://github.com/CptnKickass/PuddingBot/blob/master/${item}"
				echo "${item}"
			fi
		done
	fi
fi
exit 0

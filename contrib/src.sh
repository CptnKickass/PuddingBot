#!/usr/bin/env bash

## Config
# Path to search for file
searchPath="/home/goose/PuddingBot"

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("find")
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

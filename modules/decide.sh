#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("")
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
modForm=("decide" "choose")
modFormCase="No"
modHelp="Picks an item from a vertical bar separated list"
modFlag="m"

if [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	tmp="$(mktemp)"
	tr '|' '\n' <<<"${msgArr[@]:4}" > "${tmp}"
	sed -i -r "s/^( )+//g" "${tmp}"
	sed -i -r "s/( )+$//g" "${tmp}"
	readarray -t arr < "${tmp}"
	rm "${tmp}"
	echo "${arr[${RANDOM} % ${#arr[@]} ]] }"
fi

#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("bc" "read" "awk")
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "${depFail}" -eq "1" ]; then
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
modForm=("calc" "math")
modFormCase=""
modHelp="Calculates basic arithmetic and returns the result"
modFlag="m"
if [ -z "${msgArr[4]}" ]; then
	echo "This command requires a parameter"
else
	equation="${msgArr[@]:4}"
	result="$(echo "scale=3; ${equation}" | bc 2>&1)"
	if [ "${#result}" -gt "50" ]; then
		result="${result:0:50} (Truncated to first 50 characters)"
	fi
	echo "${result}"
fi
exit 0

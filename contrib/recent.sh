#!/usr/bin/env bash

## Config
# Path to search for file
searchPath="/home/goose/public_html/captain-kickass.net/files"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("find")
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
modForm=("recent" "reshare")
modFormCase=""
modHelp="Displays the most recently updated file at captain-kickass.net"
modFlag="m"

re='^[0-9]+$'
if ! [[ ${msgArr[4]} =~ ${re} ]]; then
	n="1"
elif [ -z "${msgArr[4]}" ]; then
	n="1"
elif [ "${msgArr[4]}" -gt "10" ]; then
	echo "Max results allowed to be displayed is 10"
	n="10"
else
	n="${msgArr[4]}"
fi
find ${searchPath} -type f -printf "%T@ %Tc %p\n" | sort -n | tail -n ${n} | awk '{print $8}' | while read out; do
	out="https://${out#*public_html/}"
	echo "${out}"
done

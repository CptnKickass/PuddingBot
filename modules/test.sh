#!/usr/bin/env bash

## Config
# Config options go here

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "$depFail" -eq "1" ]; then
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
modForm=("test")
modFormCase=""
modHelp="This module provides examples on how to write other modules"
modFlag="m"
echo "\${com}: ${com}"
echo "\${msgArr[@]}: ${msgArr[@]}"
unset testArr
n="0"
for i in "${msgArr[@]}"; do
	testArr+=("\${msgArr[${n}]}: ${i}  || ")
	n="$(( ${n} + 1 ))"
done
testStr="${testArr[@]}"
echo "${testStr%  ||*}"
exit 0

#!/usr/bin/env bash

## Config

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
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
modForm=("explain")
modFormCase=""
modHelp="Sometimes people need things explained to them. This module assists in that."
modFlag="m"
target="${msgArr[5]}"
# Format should be:
# :N!U@H PRIVMSG ${target} :!explain <to> ${target} <that> ${explain}
explain="${msgArr[@]:7}"
re="I'm"
explain="${explain//you\'re/$re}"
re="I"
explain="${explain//you/$re}"
re="you're"
explain="${explain//she\'s/$re}"
explain="${explain//he\'s/$re}"
explain="${explain//they\'re/$re}"
if [ -z "$target" ]; then
	echo "This command requires a target"
elif [ -z "$explain" ]; then
	echo "You didn't tell me what to explain"
	echo "(Format is: !explain to SnoFox that he's a faggot)"
else
	echo "${target}: ${explain}"
fi
exit 0

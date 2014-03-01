#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("ispell")
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
modForm=("spell" "ispell")
modFormCase=""
modHelp="Provides spell check functionality via ispell"
modFlag="m"
msg="$@"
if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
	echo "This command requires a parameter"
elif [ -n "$(echo "$msg" | awk '{print $5}')" ] && [ -n "$(echo "$msg" | awk '{print $6}')" ]; then
	echo "Too many parameters for command"
else
	spellResult="$(echo "$msg" | awk '{print $5}' | ispell | head -n 2 | tail -n 1)"
	spellResultParsed="$(read -r one rest <<<"$spellResult"; echo "$rest")"
	echo "${spellResultParsed}"
fi
exit 0

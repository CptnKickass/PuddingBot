#!/usr/bin/env bash

## Config
# None

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

modHook="format"
modForm=("^.*!.*@.* PRIVMSG (#|&).*:.*eat (a )?dick.*$" "^.*!.*@.* PRIVMSG (#|&).*:${comPrefix}eat(a)?dick")
modFormCase="No"
modHelp="Handles dickery"
modFlag="m"
echo "No, you eat a dick ${senderNick}"
exit 0

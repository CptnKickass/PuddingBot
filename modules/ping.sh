#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
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

modHook="prefix"
modForm=("ping" "pong")
modFormCase=""
modHelp="Responds to pings"
modFlag="m"
case "${msgArr[3],,}" in
	:${comPrefix}ping) echo "Pong!";;
	:${comPrefix}pong) echo "Ping!";;
esac
exit 0

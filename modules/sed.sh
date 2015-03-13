#!/usr/bin/env bash

## Config
# None

## Source
# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("sed")
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

modHook="Format"
modForm=("^.*PRIVMSG.*:s/.*/.*/(i|g)?$")
modFormCase="No"
modHelp="Provides sed functionality"
modFlag="m"
target="${msgArr[2]}"
sedCom="$(egrep -o -i "s/.*/.*/(i|g|ig)?$" <<<"${msgArr[@]}")"
sedItem="${sedCom#s/}"
sedItem="${sedItem%/*/*}"
if [ -n "${sedItem}" ]; then
	sedFlag="${sedCom##*/}"
	if [[ "${sedFlag}" == "i" ]]; then
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep -i "${sedItem}" | tail -n 1)"
	else
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep "${sedItem}" | tail -n 1)"
	fi
	prevSend="$(awk '{print $1}' <<<"${prevLine}" | sed "s/!.*//" | sed "s/^://")"
	line="$(read -r one two three rest <<<"${prevLine}"; echo "${rest}")"
	line="${line#:}"
	if [ -n "${line}" ]; then
		lineFixed="$(sed -E "${sedCom}" <<<"${line}")"
		if ! [[ "${lineFixed}" == "${line}" ]] && [ "${#lineFixed}" -le "200" ]; then
			echo "[FTFY] <${prevSend}> ${lineFixed}"
		elif ! [[ "${lineFixed}" == "${line}" ]] && [ "${#lineFixed}" -gt "200" ]; then
			echo "sed response not sent due to result being over 200 characters"
		fi
	fi
fi
exit 0

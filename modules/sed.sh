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

if [ -e "var/.conf" ]; then
	source var/.conf
else
	echo -e "Unable to locate \"${red}\$input${reset}\" file! (Is bot running?) Exiting."
	exit 1
fi


modHook="Format"
modForm=("^.*PRIVMSG.*:s/.*/.*/(i|g)?$")
modFormCase="No"
modHelp="Provides sed functionality"
modFlag="m"
msg="$@"
target="$(awk '{print $3}' <<<"$msg")"
sedCom="$(echo "$msg" | egrep -o -i "s/.*/.*/(i|g|ig)?$")"
sedItem="${sedCom#s/}"
sedItem="${sedItem%/*/*}"
if [ -n "$sedItem" ]; then
	sedFlag="${sedCom##*/}"
	if [[ "$sedFlag" == "i" ]]; then
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep -i "${sedItem}" | tail -n 1)"
	else
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep "${sedItem}" | tail -n 1)"
	fi
	prevSend="$(echo "$prevLine" | awk '{print $1}' | sed "s/!.*//" | sed "s/^://")"
	line="$(read -r one two three rest <<<"${prevLine}"; echo "$rest")"
	line="${line#:}"
	if [ -n "$line" ]; then
		lineFixed="$(echo "$line" | sed -E "${sedCom}")"
		if ! [[ "$lineFixed" == "${line}" ]]; then
			echo "[FTFY] <${prevSend}> $lineFixed"
		fi
	fi
fi
exit 0

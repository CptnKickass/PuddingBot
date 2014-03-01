#!/usr/bin/env bash

## Config
# None

## Source
if [ -e "var/.conf" ]; then
	source var/.conf
else
	echo -e "Unable to locate \"${red}\$input${reset}\" file! (Is bot running?) Exiting."
	exit 1
fi

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

modHook="Format"
modForm=("^.*PRIVMSG.*:s/.+/.+/[i|g]?$")
modFormCase="Yes"
modHelp="Provides sed functionality"
modFlag="m"
msg="$@"
echo "You typed !example, your message was ${msg}"
exit 0
sedCom="$(echo "$message" | egrep -o -i "s\/.*\/.*\/(i|g|ig)?")"
sedItem="${sedCom#s/}"
sedItem="${sedItem%/*/*}"
prevLine="$(fgrep "PRIVMSG" "${input}" | fgrep "${sedItem}" | tail -n 2 | head -n 1)"
prevSend="$(echo "$prevLine" | awk '{print $1}' | sed "s/!.*//" | sed "s/^://")"
line="$(read -r one two three rest <<<"${prevLine}"; echo "$rest" | sed "s/^://")"
if [ -n "$line" ]; then
	lineFixed="$(echo "$line" | sed "${sedCom}")"
	echo "PRIVMSG $senderTarget :[FTFY] <${prevSend}> $lineFixed" >> $output
fi
exit 0

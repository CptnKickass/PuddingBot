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
modHook="Format"
modForm=(":^.+!.+@.+ PRIVMSG.*(http(s)?://)?(ck|sf).net[^ \"\(\)\<\>]*")
modFormCase="No"
modHelp="Extends ck.net -> captain-kickass.net and sf.net -> snofox.net"
modFlag="m"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@
message="$@"
isCk="0"
isCk="$(egrep -c "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*" <<<"${message}")"
if [ "$isCk" -ge "1" ]; then
	egrep -o "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*" <<<"${message}" | while read ckUrl; do
		fixedUrl="$(sed "s/.*ck\.net/https:\/\/captain-kickass\.net/i" <<<"${ckUrl}")"
		fixedUrl="$(sed "s/.*sf\.net/http:\/\/snofox\.net/i" <<<"${ckUrl}")"
		echo "[Expanded URL] $fixedUrl"
	done
fi
exit 0

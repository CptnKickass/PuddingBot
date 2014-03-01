#!/usr/bin/env bash

if [ "$1" == "--build" ]; then
	IFS=$'\r\n' mods=($(<var/.mods))
	# The modules to load are now in ${mods[@]}
	rm -rf var/.mods
	mkdir var/.mods
	
	for i in "${mods[@]}"; do
		cp "modules/${i}" "var/.mods/${i}"
		modType="$(egrep -m 1 "^modHook=" "var/.mods/${i}")"
		modType="${modType#*=}"
		modType="$(tr '[:upper:]' '[:lower:]' <<<"$modType")"
		modHook="$(egrep -m 1 "^modForm=" "var/.mods/${i}")"
		modHook="${modHook#*=}"
		modCase="$(egrep -m 1 "^modFormCase=" "var/.mods/${i}")"
		modCase="${modCase#*=}"
		modCase="$(tr '[:upper:]' '[:lower:]' <<<"$modCase")"
		modHelp="$(egrep -m 1 "^modHelp=" "var/.mods/${i}")"
		modHelp="${modHelp#*=}"
		modFlag="$(egrep -m 1 "^modFlag=" "var/.mods/${i}")"
		modFlag="${modFlag#*=}"
		echo "mod: $i" >> var/.mods/hook
		echo "type: ${modType}" >> var/.mods/hook
		echo "hook: ${modHook}" >> var/.mods/hook
		echo "case: ${modCase}" >> var/.mods/hook
		echo "help: ${modHelp}" >> var/.mods/hook
		echo "flag: ${modFlag}" >> var/.mods/hook
	done
exit 0
fi

# If we're not called with --build, assume that we're being asked to handle a module
message="$@"
while read i; do
	mod="$(head -n 1 <<<"$i")"
	mod="${mod: }"
	modType="$(head -n 2 <<<"$i" | tail -n 1)"
	modType="${modType: }"
	modHook="$(head -n 3 <<<"$i" | tail -n 1)"
	modHook="${modHook: }"
	modCase="$(head -n 4 <<<"$i" | tail -n 1)"
	modCase="${modCase: }"
	modHelp="$(head -n 5 <<<"$i" | tail -n 1)"
	modHelp="${modHelp: }"
	modFlag="$(head -n 6 <<<"$i" | tail -n 1)"
	modFlag="${modFlag: }"
	echo "mod: $i"
	echo "type: ${type}"
	echo "hook: ${hook}"
	echo "case: ${case}"
	echo "help: ${help}"
	echo "flag: ${flag}"
done < "$(fgrep -A 5 "mod: " "var/.mods/hook")"

if [ "$(echo "$message" | awk '{print $4}' | cut -b 2)" == "${comPrefix}" ]; then
	isCom="1"
	com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
	com="${com:2}"
# This is a command beginning with ${nick}: ${nick}; or ${nick},
elif [[ "$(awk '{print $4}' <<<"$message")" == ":${nick}"?([:;,]) ]]; then
	isCom="1"
	message="$(sed -E "s/:${nick}[:;,]? //" <<<"$message")"
	com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
# It's a PM
elif [ "$isPm" -eq "1" ]; then
	isCom="1"
	com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
	com="${com:1}"
else
	isCom="0"
fi

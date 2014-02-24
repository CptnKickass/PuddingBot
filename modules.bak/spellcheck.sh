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

# Hook should either be "Prefix" or "Format". Prefix will patch whatever
# the $comPrefix is, i.e. !command. Format will match a message specific
# format, i.e. the sed module.
modHook="Prefix"

# This is where the module source should start
msg="$@"
msg="${msg#${0} }"
com="$(echo "$msg" | awk '{print $4}')"
com="${com:2}"
case "$com" in
	spell)
	if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
		echo "This command requires a parameter"
	elif [ -n "$(echo "$msg" | awk '{print $5}')" ] && [ -n "$(echo "$msg" | awk '{print $6}')" ]; then
		echo "Too many parameters for command"
	else
		spellResult="$(echo "$msg" | awk '{print $5}' | ispell | head -n 2 | tail -n 1)"
		spellResultParsed="$(read -r one rest <<<"$spellResult"; echo "$rest")"
		echo "${spellResultParsed}"
	fi
	;;
esac
exit 0

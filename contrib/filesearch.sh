#!/usr/bin/env bash

## Config
searchPath="/mnt/storage/goose/public_html/captain-kickass.net"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=("find")
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
hook="Prefix"

# This is where the module source should start
msg="$@"
msg="${msg#${0} }"
com="$(echo "$msg" | awk '{print $4}')"
com="${com:2}"
case "$com" in
	find|search)
		if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
			echo "This command requires a parameter"
		else
			searchItem="$(read -r one two three four rest <<<"$msg"; echo "$rest")"
			results="$(find "${searchPath}" -iname "${searchItem}")"
			resultsNum="$(echo "$results" | wc -l)"
			if [  -z "$results" ]; then
				echo "No results found"
			elif [ "$resultsNum" -gt "10" ]; then
				echo "More than 10 results returned. Not printing to prevent spam."
			else
				echo "$results" | while read line; do
					item="${line#*public_html/}"
					item="https://${item}"
					echo "${item}"
				done
			fi
		fi
		;;
esac
exit 0

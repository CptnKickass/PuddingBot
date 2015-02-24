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

modHook="Prefix"
modForm=("karma")
modFormCase=""
modHelp="Checks a user's karma"
modFlag="m"
msg="$@"
seenTarget="$(awk '{print $5}' <<<"$msg")"
# This method is preferred, but pisses off vim's syntax. So I'll use sed for debugging purposes.
#seenTarget="${seenTarget//\'/''}"
seenTarget="$(sed "s/'/''/g" <<<"${seenTarget}")"
sqlUserExists="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM karma WHERE nick = '${seenTarget}';")"
if [ -z "${sqlUserExists}" ]; then
	# Returned nothing. User does not exist.
	echo "I have no such record of anyone by the nick ${seenTarget}"
else
	# User does exist.
	karma="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT value FROM karma WHERE nick = '${seenTarget}';" | tail -n 1)"
	echo "${seenTarget} has a karma of ${karma}"
fi
exit 0

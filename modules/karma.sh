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

if [[ "${sqlSupport}" -eq "0" ]]; then
	echo "This module requires SQL support to be enabled"
	exit 255
fi

modHook="Prefix"
modForm=("karma")
modFormCase=""
modHelp="Checks a user's karma"
modFlag="m"
karmaTarget="${msgArr[4]}"
if [[ -z "${karmaTarget}" ]]; then
	karmaTarget="${senderNick}"
fi
# This method is preferred, but pisses off vim's syntax. So I'll use sed for debugging purposes.
#karmaTarget="${karmaTarget//\'/''}"
karmaTarget="$(sed "s/'/''/g" <<<"${karmaTarget}")"
karmaTarget="$(sed 's/\\/\\\\/g' <<<"${karmaTarget}")"
sqlUserExists="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM karma WHERE nick = '${karmaTarget}';")"
if [[ -z "${sqlUserExists}" ]]; then
	# Returned nothing. User does not exist.
	echo "${karmaTarget} has no karma"
else
	# User does exist.
	karma="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT value FROM karma WHERE nick = '${karmaTarget}';")"
	if [[ "${karmaTarget,,}" == "${nick,,}" ]]; then
		if [[ "${karma}" -eq "0" ]]; then
			echo "I have no karma"
		else
			echo "I have a karma of ${karma}"
		fi
	elif [[ "${karma}" -eq "0" ]]; then
		echo "${karmaTarget} has no karma"
	else
		echo "${karmaTarget} has a karma of ${karma}"
	fi
fi

#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=()
	if [[ "${#apis[@]}" -ne "0" ]]; then
		if [[ -e "api.conf" ]]; then
			for i in "${apis[@]}"; do
				val="$(egrep "^${i}" "api.conf")"
				val="${val#${i}=\"}"
				val="${val%\"}"
				if [[ -z "${val}" ]]; then
					echo -e "Missing api key \"${red}${i}${reset}\"! Exiting."
					apiFail="1"
				fi
			done
		else
			path="$(pwd)"
			path="${path##*/}"
			path="./${path}/${0##*/}"
			echo "Unable to locate \"api.conf\"!"
			echo "(Are you running the dependency check from the main directory?)"
			echo "(ex: ${path} --dep-check)"
			exit 255
		fi
	fi
	if [[ "${sqlSupport}" -eq "0" ]]; then
		echo "MySQL support required for this module, but not enabled!"
		depFail="1"
	fi
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
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

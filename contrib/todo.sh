#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("git")
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
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

modHook="Prefix"
modForm=("todo")
modFormCase="No"
modHelp="Add items to Pudding's todo list"
modFlag="A"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${modFlag}"; then
		if [[ "${msgArr[4]}" =~ "push" ]]; then
			git add TODO.md 2>&1
			git commit -m "Updated todo file" 2>&1
			git push 2>&1
		else
			toAdd="${msgArr[@]:4}"
			echo "* ${toAdd}" >> TODO.md
			echo "Added \"* ${toAdd}\" to TODO.md"
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

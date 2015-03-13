#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("git")
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "${depFail}" -eq "1" ]; then
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
modForm=("todo")
modFormCase="No"
modHelp="Add items to Pudding's todo list"
modFlag="A"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
if [ "${loggedIn}" -eq "1" ]; then
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
exit 0

#!/usr/bin/env bash
reqFlag="A"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		if ! [[ -e "var/.silence" ]]; then
			echo "Going silent"
			touch "var/.silence1"
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

#!/usr/bin/env bash

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [ "${loggedIn}" -eq "0" ]; then
	echo "You are not logged in"
else
	if [ "$(fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $2}')" -eq "1" ]; then
		# Only 1 clone logged in, so we can delete their entry
		sed -i "/${senderUser}@${senderHost}/d" "var/.admins"
		echo "Successfully logged out"
	else
		# More than 1 clone logged in. Remove only the appropriate u@h
		sed -i "s/ ${senderUser}@${senderHost}//" "var/.admins"
		echo "Successfully logged out"
	fi
fi

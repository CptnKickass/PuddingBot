#!/usr/bin/env bash

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "0" ]]; then
	echo "You are not logged in"
else
	aLine="$(fgrep -n "${senderUser}@${senderHost}" "var/.admins")"
	lineNo="${aLine%%:*}"
	aLine="${aLine#${lineNo}:}"
	sed -i "${lineNo}d" "var/.admins"
	if [[ "$(awk '{print $2}' <<<"${aLine}")" -eq "1" ]]; then
		# Only 1 clone logged in, so we can delete their entry
		echo "Successfully logged out"
	else
		# More than 1 clone logged in. Remove only the appropriate u@h
		newLine="${aLine/${senderUser}@${senderHost}/}"
		echo "${newLine}" >> "var/.admins"
		echo "Successfully logged out"
	fi
fi

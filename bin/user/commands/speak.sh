#!/usr/bin/env bash
reqFlag="s"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		if [[ -z "${msgArr[4]}" ]]; then
			echo "This command requires a parameter"
		elif ! egrep -q "^(#|&)" <<<"${msgArr[4]})"; then
			echo "${msgArr[4]} does not appear to be a valid channel"
		else
			sayMsg="$(read -r one two three four five rest <<<"${message}"; echo "${rest}")"
			echo "PRIVMSG ${msgArr[4]} :${sayMsg}" >> ${output}
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

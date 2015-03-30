#!/usr/bin/env sh
reqFlag="a"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		cat "var/.admins" | while read item; do
			lUser="$(awk '{print $1}' <<<"${item}")"
			lHost="$(read -r one two three rest <<<"${item}"; echo "${rest}")"
			echo "${lUser} logged in from ${lHost}" 
		done
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

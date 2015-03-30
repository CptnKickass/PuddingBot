#!/usr/bin/env bash
reqFlag="A"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		./controller.sh --from-irc-restart > /dev/null 2>&1 &
		echo "QUIT :Restarting per ${senderNick}" >> ${output}
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

#!/usr/bin/env bash
reqFlag="a"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		source var/.status
		echo "I am ${nick}, currently connected to ${server} (${actualServer} on ${networkName}) via port ${port}. I am hosted on $(uname -n). My PID is $(<var/bot.pid) and my owner is ${owner} (${ownerEmail})."
	else
		echo "I am ${nick}. My owner is ${owner} (${ownerEmail})"
	fi
else
	echo "I am ${nick}. My owner is ${owner} (${ownerEmail})"
fi

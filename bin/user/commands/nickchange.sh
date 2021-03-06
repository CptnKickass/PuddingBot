#!/usr/bin/env bash
reqFlag="s"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		if [[ -z "${msgArr[4]}" ]]; then
			echo "This command requires a parameter"
		else
			echo "NICK ${msgArr[4]}" >> ${output}
			if [[ "${logIn}" -eq "1" ]]; then
				source ./bin/core/log.sh --nick
			fi
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

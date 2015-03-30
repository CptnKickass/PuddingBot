#!/usr/bin/env bash
reqFlag="L"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		target="${msgArr[4]}"
		if [[ -n "${target}" ]]; then
			loggedIn="$(egrep -c "^${target}" "var/.admins")"
			if [[ "${loggedIn}" -eq "0" ]]; then
				echo "${target} is not logged in"
			else
				sed -i "/^${target}/d" "var/.admins"
				echo "${target} successfully force logged out"
			fi
		else
			echo "This command requires a parameter"
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

#!/usr/bin/env bash

reqFlag="i"
loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [ "${loggedIn}" -eq "1" ]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		if [ -z "${msgArr[4]}" ]; then
			echo "This command requires a command parameter"
		else
			ignoreHost="${msgArr[5]}"
			ignoreHost="${ignoreHost,,}"
			caseMsg="${msgArr[4]}"
			case "${caseMsg,,}" in
				list)
					ignoreList="$(<var/ignore.db)"
					if [ -n "${ignoreList}" ]; then
						echo "${ignoreList}"
					else
						echo "Ignore list empty"
					fi
					;;
				add)
					if [ -z "${msgArr[5]}" ]; then
						echo "This command requires a host parameter"
					# It's important to check for patterns with fgrep instead of
					# egrep, because we don't want a pattern we've already set
					# blocking a new pattern we're trying to set
					elif fgrep -q "${ignoreHost}" var/ignore.db; then
						echo "Host ${ignoreHost} already being ignored"
					else
						echo "${ignoreHost}" >> var/ignore.db
						echo "Added ${ignoreHost} to ignore list."
					fi
					;;
				del)
					if [ -z "${msgArr[5]}" ]; then
						echo "This command requires a host parameter"
					elif fgrep -q "${ignoreHost}" var/ignore.db; then
						escapedHost="${ignoreHost//\*/\\*}"
						sed -i "/${escapedHost}/d" var/ignore.db
						echo "Removed ${ignoreHost} from ignore list."
					else
						echo "Host ${ignoreHost} not being ignored"
					fi
					;;
				*)
					echo "Invalid option"
					;;
			esac
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

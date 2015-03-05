#!/usr/bin/env bash

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
if [ "$loggedIn" -eq "1" ]; then
	loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
	arg1="${msgArr[4]}"
	case "${arg1,,}" in
		password)
			lPass="${msgArr[5]}"
			lHash="$(echo -n "$lPass" | sha256sum | awk '{print $1}')"
			if [ -z "${lPass}" ]; then
				echo "You must provide a password. Format is: set PASSWORD"
			else
				sed -i "s/pass=\".*\"/pass=\"${lHash}\"/" "${userDir}/${loggedInUser}.conf"
				echo "Successfully changed password to \"${lPass}\"."
			fi
			;;
		clones)
			re='^[0-9]+$'
			lClones="${msgArr[5]}"
			if [ -z "${lClones}" ]; then
				echo "You must provide a number of clones. Format is: set CLONES N (Where \"N\" is your desired number of alloted clones)"
			elif [[ $lClones =~ $re ]]; then
				sed -i "s/clones=\".*\"/clones=\"${lHash}\"/" "${userDir}/${loggedInUser}.conf"
				echo "Successfully changed password to \"${lPass}\"."
			else
				echo "You must provide a number of clones. Format is: set CLONES N (Where \"N\" is your desired number of alloted clones)"
			fi
			;;
		allowedhost)
			case "${msgArr[5]}" in
				list)
					IFS=$'\r\n' :; hostArr=($(egrep "^allowedLoginHost=\".*\"$" "${userDir}/${loggedInUser}.conf"))
					if [ "${#hostArr[@]}" -eq "0" ]; then
						echo "No authenticated login hosts set to ${loggedInUser}"
					else
						hostArr=(${hostArr[@]#allowedLoginHost=\"})
						hostArr=(${hostArr[@]%\"})
						echo "Authenticated hosts: ${hostArr[@]}"
					fi
				;;
				add)
					hostToAdd="${msgArr[6]}"
					if fgrep -q "*"<<<"${hostToAdd}"; then
						echo "Unable to add host; improper formatting (Please use proper \"USER@HOST\" formatting. Wildcards are not accepted.)"
					elif ! egrep -q ".*@.*" <<<"${hostToAdd}"; then
						echo "Unable to add host; improper formatting (Please use proper \"USER@HOST\" formatting. Wildcards are not accepted.)"
					elif egrep -q "^allowedLoginHost=\"${hostToAdd}\"$" "${userDir}/${loggedInUser}.conf"; then
						echo "Unable to add host; already exists."
					else
						echo "allowedLoginHost=\"${hostToAdd}\"" >> "${userDir}/${loggedInUser}.conf"
						echo "Added login host \"${hostToAdd}\" for user ${loggedInUser}"
					fi
				;;
				del|delete|remove)
					hostToDel="${msgArr[6]}"
					if fgrep -q "allowedLoginHost=\"${hostToDel}\"" "${userDir}/${loggedInUser}.conf"; then
						sed -i "/allowedLoginHost=\"${hostToDel}\"/d" "${userDir}/${loggedInUser}.conf"
						echo "Removed login host \"${hostToDel}\" for user ${loggedInUser}"
					else
						echo "Login host \"${hostToDel}\" does not appear to be an allowed host for ${loggedInUser}. Check allowed hosts with command: SET ALLOWEDHOST LIST"
					fi
				;;
				*)
					echo "Invalid command. Valid SET ALLOWEDHOST commands are: List, Add, Del, Delete, Remove"
				;;
			esac
			;;
		meta)
			case "${msgArr[5]}" in
				list)
					IFS=$'\r\n' :; metaArr=($(egrep "^meta=\".*\"$" "${userDir}/${loggedInUser}.conf"))
					if [ "${#metaArr[@]}" -eq "0" ]; then
						echo "No meta data set for ${loggedInUser}"
					else
						metaArr=(${metaArr[@]#meta=\"})
						metaArr=(${metaArr[@]%\"})
						echo "Meta data set for ${loggedInUser}: ${metaArr[@]}"
					fi
				;;
				add)
					metaToAdd="${msgArr[6]}"
					if [ -z "$metaToAdd" ]; then
						echo "Unable to add meta; no data input.)"
					else
						echo "meta=\"${metaToAdd}\"" >> "${userDir}/${loggedInUser}.conf"
						echo "Added meta data \"${metaToAdd}\" for user ${loggedInUser}"
					fi
				;;
				del|delete|remove)
					metaToDel="${msgArr[6]}"
					if fgrep -q "meta=\"${metaToDel}\"" "${userDir}/${loggedInUser}.conf"; then
						sed -i "/meta=\"${metaToDel}\"/d" "${userDir}/${loggedInUser}.conf"
						echo "Removed meta data \"${metaToDel}\" for user ${loggedInUser}"
					else
						echo "Meta data \"${metaToDel}\" does not appear to set for ${loggedInUser}. Check set meta data with command: SET META LIST"
					fi
				;;
				*)
					echo "Invalid command. Valid SET META commands are: List, Add, Del, Delete, Remove"
				;;
			esac
			;;
		removeacct|removeaccount)
			if [ -z "${msgArr[5]}" ]; then
				if egrep -q "^removeKey=\"" "${userDir}/${loggedInUser}.conf"; then
					removeKey="$(egrep "^removeKey=\"" "${userDir}/${loggedInUser}.conf")"
					removeKey="${removeKey#removeKey=\"}"
					removeKey="${removeKey%\"}"
					echo "Your account (${loggedInUser}) has already been marked for deletion. Please reply \"SET REMOVEACCT ${removeKey}\" to confirm deletion of account."
				else
					removeKey="$(dd if=/dev/urandom count=1 2>/dev/null | perl -pe 's/[^[:alpha:]]//g' | cut -b 1-16)"
					echo "removeKey=\"${removeKey}\"" >> "${userDir}/${loggedInUser}.conf"
					echo "Your account (${loggedInUser}) has been marked for delition. Please reply \"SET REMOVEACCT ${removeKey}\" to confirm deletion of this account. Reply \"SET REMOVEACCT cancel\" to cancel mark for deletion."
				fi
			elif [[ "${msgArr[5]}" =~ "cancel" ]]; then
				if egrep -q "^removeKey=\"" "${userDir}/${loggedInUser}.conf"; then
					sed -i "/removeKey=\"/d" "${userDir}/${loggedInUser}.conf"
					echo "Mark for deletion for your account (${loggedInUser}) has been removed."
				else
					echo "Your account (${loggedInUser}) was not marked for deletion."
				fi
			elif egrep -q "^removeKey=\"${msgArr[5]}\"$" "${userDir}/${loggedInUser}.conf"; then
				echo "Deletion for account ${loggedInUser} confirmed. Removing all user data..."
				rm -f "${userDir}/${loggedInUser}.conf"
				if [ -e "${userDir}/${loggedInUser}.conf" ]; then
					echo "Unable to remove user data! Please contact an administrator."
				else
					echo "${loggedInUser} purged from data files. Logging ${loggedInUser} out of bot..."
					sed -i "/^${loggedInUser}/d" "var/.admins"
					if egrep -q "^${loggedInUser}" "var/.admins"; then
						echo "Unable to log ${loggedInUser} out! Please contact an administrator."
					else
						echo "${loggedInUser} removed from logged in users."
					fi
				fi
			else
				if egrep -q "^removeKey=\"" "${userDir}/${loggedInUser}.conf"; then
					removeKey="$(egrep "^removeKey=\"" "${userDir}/${loggedInUser}.conf")"
					removeKey="${removeKey#removeKey=\"}"
					removeKey="${removeKey%\"}"
					echo "Your account (${loggedInUser}) has already been marked for deletion. Please reply \"SET REMOVEACCT ${removeKey}\" to confirm deletion of account."
				else
					echo "Invalid command. Reply \"SET REMOVEACCT\" to initiate account removal, or \"SET REMOVEACCT cancel\" to cancel mark for deletion of account."
				fi
			fi
			;;
		*)
			echo "Invalid command. Valid SET commands are: Password, Clones, AllowedHost, Meta"
			;;
	esac
else
	echo "You must be logged in to use this command"
fi

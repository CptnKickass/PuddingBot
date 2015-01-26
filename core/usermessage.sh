#!/usr/bin/env bash

source var/.conf
message="$@"
senderTarget="$(echo "$message" | awk '{print $3}')"
senderAction="$(echo "$message" | awk '{print $2}')"
senderFull="$(echo "$message" | awk '{print $1}')"
senderFull="${senderFull#:}"
senderNick="${senderFull%!*}"
senderUser="${senderFull#*!}"
senderUser="${senderUser%@*}"
senderHost="${senderFull#*@}"

# For simplicities sake, I'll keep all commands in this function
comExec () {
case "$com" in
	register)
		if [ "$isPm" -eq "1" ]; then
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
			if [ "$loggedIn" -eq "0" ]; then
				lUser="$(awk '{print $5}' <<<"$message")"
				lPass="$(awk '{print $6}' <<<"$message")"
				lHash="$(echo -n "$lPass" | sha256sum | awk '{print $1}')"
				if [ -z "${lUser}" ]; then
					echo "You must provide a username. Format is: \"register USERNAME PASSWORD\" ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
				elif [ -z "${lPass}" ]; then
					echo "You must provide a password. Format is: \"register USERNAME PASSWORD\" ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
				fi
				if [ -n "${lUser}" ] && [ -n "${lPass}" ]; then
					if [ -e "${userDir}/${lUser}.conf" ]; then
						echo "That username has already been taken. Please choose another."
					else
						echo "user=\"${lUser}\"" > "${userDir}/${lUser}.conf"
						echo "pass=\"${lHash}\"" >> "${userDir}/${lUser}.conf"
						genFlags="$(egrep "^genFlags=" "${dataDir}/pudding.conf")"
						genFlags="${genFlags/genF/f}"
						echo "${genFlags}" >> "${userDir}/${lUser}.conf"
						echo "clones=\"3\"" >> "${userDir}/${lUser}.conf"
						echo "Successfully registered with username \"${lUser}\" and password \"${lPass}\". Please note that your default alloted clones that can be logged in at once is 3. Please use: \"set clones N\" to change this, where \"N\" is your desired number of clones."
					fi
				fi
			else
				loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
				echo "You are already logged in as ${loggedInUser}."
			fi
		else
			echo "Registration must be done in PM"
		fi
		;;
	set)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
			arg1="$(awk '{print $5}' <<<"$message")"
			case "${arg1,,}" in
				password)
					lPass="$(awk '{print $6}' <<<"$message")"
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
					lClones="$(awk '{print $6}' <<<"$message")"
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
					case "$(awk '{print $6}' <<<"$message")" in
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
							hostToAdd="$(awk '{print $7}' <<<"$message")"
							if echo "$hostToAdd" | fgrep -q "*"; then
								echo "Unable to add host; improper formatting (Please use proper \"USER@HOST\" formatting. Wildcards are not accepted.)"
							elif ! echo "$hostToAdd" | egrep -q ".*@.*"; then
								echo "Unable to add host; improper formatting (Please use proper \"USER@HOST\" formatting. Wildcards are not accepted.)"
							elif egrep -q "^allowedLoginHost=\"${hostToAdd}\"$" "${userDir}/${loggedInUser}.conf"; then
								echo "Unable to add host; already exists."
							else
								echo "allowedLoginHost=\"${hostToAdd}\"" >> "${userDir}/${loggedInUser}.conf"
								echo "Added login host \"${hostToAdd}\" for user ${loggedInUser}"
							fi
						;;
						del|delete|remove)
							hostToDel="$(awk '{print $7}' <<<"$message")"
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
					case "$(awk '{print $6}' <<<"$message")" in
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
							metaToAdd="$(awk '{print $7}' <<<"$message")"
							if [ -z "$metaToAdd" ]; then
								echo "Unable to add meta; no data input.)"
							else
								echo "meta=\"${metaToAdd}\"" >> "${userDir}/${loggedInUser}.conf"
								echo "Added meta data \"${metaToAdd}\" for user ${loggedInUser}"
							fi
						;;
						del|delete|remove)
							metaToDel="$(awk '{print $7}' <<<"$message")"
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
					if [ -z "$(awk '{print $6}' <<<"$message")" ]; then
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
					elif [[ "$(awk '{print $6}' <<<"$message")" =~ "cancel" ]]; then
						if egrep -q "^removeKey=\"" "${userDir}/${loggedInUser}.conf"; then
							sed -i "/removeKey=\"/d" "${userDir}/${loggedInUser}.conf"
							echo "Mark for deletion for your account (${loggedInUser}) has been removed."
						else
							echo "Your account (${loggedInUser}) was not marked for deletion."
						fi
					elif egrep -q "^removeKey=\"$(awk '{print $6}' <<<"$message")\"$" "${userDir}/${loggedInUser}.conf"; then
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
		;;
	login)
		if [ "$isPm" -eq "1" ]; then
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
			if [ "$loggedIn" -eq "0" ]; then
				lUser="$(awk '{print $5}' <<<"$message")"
				lPass="$(awk '{print $6}' <<<"$message")"
				lHash="$(echo -n "$lPass" | sha256sum | awk '{print $1}')"
				if egrep -q "^user=\"${lUser}\"$" ${userDir}/*.conf; then
					matchFile="$(egrep "^user=\"${lUser}\"$" ${userDir}/*.conf /dev/null)"
					matchFile="${matchFile%%:*}"
					# User exists
					if fgrep -q "pass=\"${lHash}\"" "${matchFile}"; then
						if egrep -q "^${lUser}" var/.admins; then
							# User is already logged in. How many clones are they allowed?
							numClonesAllowed="$(egrep "clones=\"[0-9]+\"" "${matchFile}")"
							numClonesAllowed="${numClonesAllowed%\"}"
							numClonesAllowed="${numClonesAllowed#*\"}"
							numClones="$(egrep "^${lUser}" var/.admins | awk '{print $2}')"
							if [ "$numClones" -lt "$numClonesAllowed" ]; then
								# Less than their alloted number
								userLine="$(egrep "^${lUser}" var/.admins)"
								numClones="$(( $numClones + 1 ))"
								allowedFlags="$(awk '{print $3}' <<<"$userLine")"
								existingHosts="$(read -r one two three rest <<<"$userLine"; echo "$rest")"
								sed -i "/^${lHost}/d" var/.admins
								echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> var/.admins
								echo "Successfully logged in."
							else
								# Their alloted number
								echo "User ${lUser} is already logged in with the maximum number of alloted clones."
							fi
						else
							# Password matches user, and they don't have any clones logged in
							allowedFlags="$(egrep "flags=\"[a-z|A-Z]+\"" "${matchFile}")"
							allowedFlags="${allowedFlags%\"}"
							allowedFlags="${allowedFlags#*\"}"
							echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> var/.admins
							echo "Successfully logged in."
						fi
					else
						# Password does not match user
						echo "Invalid login."
					fi
				else
					# No such user
					echo "Invalid login."
				fi
			else
				loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
				echo "Already logged in as ${loggedInUser}."
			fi
		else
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
			if [ "$loggedIn" -eq "0" ]; then
				if egrep -q "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null; then
					matchFile="$(egrep "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null)"
					matchFile="${matchFile%%:*}"
					lUser="$(egrep "^user=\"" "${matchFile}")"
					lUser="${lUser#*\"}"
					lUser="${lUser%\"}"
					# User exists and matches a known allowed host
					if egrep -q "^${lUser}" var/.admins; then
						# User is already logged in. How many clones are they allowed?
						numClonesAllowed="$(egrep "clones=\"[0-9]+\"" "${matchFile}")"
						numClonesAllowed="${numClonesAllowed%\"}"
						numClonesAllowed="${numClonesAllowed#*\"}"
						numClones="$(egrep "^${lUser}" var/.admins | awk '{print $2}')"
						if [ "$numClones" -lt "$numClonesAllowed" ]; then
							# Less than their alloted number
							userLine="$(egrep "^${lUser}" var/.admins)"
							numClones="$(( $numClones + 1 ))"
							allowedFlags="$(awk '{print $3}' <<<"$userLine")"
							existingHosts="$(read -r one two three rest <<<"$userLine"; echo "$rest")"
							sed -i "/^${lHost}/d" var/.admins
							echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> var/.admins
							echo "Successfully logged in as ${lUser}."
						else
							# Their alloted number
							echo "User ${lUser} is already logged in with the maximum number of alloted clones."
						fi
					else
						# Password matches user, and they don't have any clones logged in
						allowedFlags="$(egrep "flags=\"[a-z|A-Z]+\"" "${matchFile}")"
						allowedFlags="${allowedFlags%\"}"
						allowedFlags="${allowedFlags#*\"}"
						echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> var/.admins
						echo "Successfully logged in as ${lUser}."
					fi
				else
					# No such user
					echo "You are not using an authenticated host. Please log in via PM."
				fi
			else
				loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
				echo "Already logged in as ${loggedInUser}."
			fi
		fi
	;;
	logout)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "0" ]; then
			echo "You are not logged in"
		else
			if [ "$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $2}')" -eq "1" ]; then
				# Only 1 clone logged in, so we can delete their entry
				sed -i "/${senderUser}@${senderHost}/d" var/.admins
				echo "Successfully logged out"
			else
				# More than 1 clone logged in. Remove only the appropriate u@h
				sed -i "s/ ${senderUser}@${senderHost}//" var/.admins
				echo "Successfully logged out"
			fi
		fi
	;;
	flogout)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="L"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				target="$(awk '{print $5}' <<<"$message")"
				if [ -n "$target" ]; then
					loggedIn="$(egrep -c "^${target}" var/.admins)"
					if [ "$loggedIn" -eq "0" ]; then
						echo "${target} is not logged in"
					else
						sed -i "/^${target}/d" var/.admins
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
	;;
	admins)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="a"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				cat var/.admins | while read item; do
					lUser="$(awk '{print $1}' <<<"$item")"
					lHost="$(read -r one two three rest <<<"$item"; echo "$rest")"
					echo "${lUser} logged in from ${lHost}" 
				done
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	join)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="t"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a parameter"
				elif [ "$(awk '{print $5}' <<<"$message" | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(awk '{print $5}' <<<"$message") does not appear to be a valid channel"
				else
					echo "JOIN $(awk '{print $5}' <<<"$message")" >> $output
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	part)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="t"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a parameter"
				elif [ "$(awk '{print $5}' <<<"$message" | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(awk '{print $5}' <<<"$message") does not appear to be a valid channel"
				else
					echo "PART $(awk '{print $5}' <<<"$message") :Leaving channel per ${senderNick}" >> $output
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	speak|say)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="s"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a parameter"
				elif [ "$(awk '{print $5}' <<<"$message" | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(awk '{print $5}' <<<"$message") does not appear to be a valid channel"
				else
					sayMsg="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
					echo "PRIVMSG $(awk '{print $5}' <<<"$message") :${sayMsg}" >> $output
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	action|do)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="s"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a parameter"
				elif [ "$(awk '{print $5}' <<<"$message" | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(awk '{print $5}' <<<"$message") does not appear to be a valid channel"
				else
					sayMsg="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
					echo "PRIVMSG $(awk '{print $5}' <<<"$message") :ACTION ${sayMsg}" >> $output
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	nick)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="s"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a parameter"
				else
					echo "NICK $(awk '{print $5}' <<<"$message")" >> $output
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	ignore)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="i"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				if [ -z "$(awk '{print $5}' <<<"$message")" ]; then
					echo "This command requires a command parameter"
				else
					ignoreHost="$(awk '{print $6}' <<<"$message")"
					ignoreHost="${ignoreHost,,}"
					caseMsg="$(awk '{print $5}' <<<"$message")"
					case "${caseMsg,,}" in
						list)
							ignoreList="$(<var/ignore.db)"
							if [ -n "$ignoreList" ]; then
								echo "$ignoreList"
							else
								echo "Ignore list empty"
							fi
							;;
						add)
							if [ -z "$(awk '{print $6}' <<<"$message")" ]; then
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
							if [ -z "$(awk '{print $6}' <<<"$message")" ]; then
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
	;;
	status)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="a"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				source var/.status
				echo "I am $nick, currently connected to $server (${actualServer} on ${networkName}) via port $port. I am hosted on $(uname -n). My PID is $(<var/bot.pid) and my owner is $owner ($ownerEmail)."
			else
				echo "I am $nick. My owner is $owner ($ownerEmail)"
			fi
		else
			echo "I am $nick. My owner is $owner ($ownerEmail)"
		fi
	;;
	die|quit|exit)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="A"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				echo "QUIT :Quitting per ${senderNick}" >> $output
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	restart)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="A"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				./controller.sh --from-irc-restart > /dev/null 2>&1 &
				echo "QUIT :Restarting per ${senderNick}" >> $output
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	uptime)
		startTime="$(egrep -m 1 "^startTime=\"" var/.status)"
		startTime="${startTime#*\"}"
		startTime="${startTime%\"}"
		timeDiff="$(( $(date +%s) - $startTime ))"
		days="$((timeDiff/60/60/24))"
		if [ "$days" -eq "1" ]; then
			days="${days} day"
		else
			days="${days} days"
		fi
		hours="$((timeDiff/60/60%24))"
		if [ "$hours" -eq "1" ]; then
			hours="${hours} hour"
		else
			hours="${hours} hours"
		fi
		minutes="$((timeDiff/60%60))"
		if [ "$minutes" -eq "1" ]; then
			minutes="${minutes} minute"
		else
			minutes="${minutes} minutes"
		fi
		seconds="$((timeDiff%60))"
		if [ "$seconds" -eq "1" ]; then
			seconds="${seconds} second"
		else
			seconds="${seconds} seconds"
		fi
		echo "Uptime: ${days}, ${hours}, ${minutes}, ${seconds}"
	;;
	help)
		unset helpTopic
		helpTopic=("(register)" "(set)" "(login)" "(logout)" "(flogout)" "(admins)" "(join)" "(part)" "(speak|say)" "(action|do)" "(nick)" "(ignore)" "(status)" "(die|quit|exit)" "(restart)" "(uptime)")
		for i in var/.mods/*.sh; do
			if fgrep -i -q "modHook=\"Prefix\"" "$i"; then
				file="$(fgrep "modForm=" "$i")"
				file="${file#*(}"
				file="${file%)}"
				file="${file//\" \"/|}"
				file="${file//\"/}"
			else
				file="${i##*/}"
				file="${file%.sh}"
			fi
			helpTopic+=("(${file})")
		done
		arg1="$(awk '{print $5}' <<<"$message")"
		if [ -z "${arg1,,}" ]; then
			echo "Available Help Topics: ${helpTopic[@]}"
		elif echo "${helpTopic[@]}" | fgrep -q "${arg1,,}"; then
			case "${arg1,,}" in
				login)
					echo "(${arg1,,}) => Logs you in to the bot"
					;;
				logout)
					echo "(${arg1,,}) => Logs you out of the bot"
					;;
				flogout)
					echo "(${arg1,,}) => Force logs another user out of the bot"
					;;
				admins)
					echo "(${arg1,,}) => Lists the currently logged in admins"
					;;
				join)
					echo "(${arg1,,}) => I'll join a channel"
					;;
				part)
					echo "(${arg1,,}) => I'll part a channel"
					;;
				speak|say)
					echo "(${arg1,,}) => I'll speak a message in a channel"
					;;
				action|do)
					echo "(${arg1,,}) => I'll do a /ME in a channel"
					;;
				nick)
					echo "(${arg1,,}) => I'll change nicks"
					;;
				ignore)
					echo "(${arg1,,}) => I'll ignore a regular expression n!u@h mask"
					;;
				status)
					echo "(${arg1,,}) => I'll give a status report"
					;;
				die|quit|exit)
					echo "(${arg1,,}) => I'll quit IRC and shut down"
					;;
				restart)
					echo "(${arg1,,}) => I'll restart, quitting IRC and joining a new spawn"
					;;
				uptime)
					echo "(${arg1,,}) => I'll give you an uptime report"
					;;
				register)
					echo "(${arg1,,}) => Registers a user into the bot. Format is: \"REGISTER username password\". ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
					;;
				set)
					arg2="$(awk '{print $6}' <<<"$message")"
					case "${arg2,,}" in
						password)
							echo "(${arg1,,})->(${arg2,,}) => Allows you to change your password. Format is: \"SET PASSWORD newpassword\". ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
							;;
						clones)
							echo "(${arg1,,})->(${arg2,,}) => Allows you to set the number of clones you want to allow to simultaneously be logged into your account. Format is: \"SET CLONES n\", where \"n\" is the number of clones you desire."
							;;
						allowedhost)
							arg3="$(awk '{print $7}' <<<"$message")"
							case "${arg3,,}" in
								list)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Lists any known white-listed IDENT@HOST masks on your account, which are authorized to be identified simply by their IDENT@HOST masks using the \"!login\" command."
									;;
								add)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Adds an IDENT@HOST mask to your account's white list, allowing anyone with that IDENT@HOST command to be identified to your account simply by using the \"!login\" command. Note that wild cards are not accepted, the match must be a full IDENT@HOST mask. Format is: \"SET ALLOWEDHOST ADD ident@host\""
									;;
								del|delete|remove)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Remove a whitelisted IDENT@HOST mask from your account, preventing it from being identified to your account simply by using the \"!login\" command. Format is: \"SET ALLOWEDHOST DEL ident@host\""
									;;
								*)
									echo "(${arg1,,})->(${arg2,,}) => Allows you to handle the pre-authenticated IDENT@HOST masks which can be used to identify an account. This means that rather than identifying with a password, you have a white listed IDENT@HOST which can use the \"!login\" command to be identified. Note that wild cards are not accepted, the match must be a full IDENT@HOST mask. Sub-commands are: List, Add, Del, Delete, Remove"
									;;
							esac
							;;
						meta)
							arg3="$(awk '{print $7}' <<<"$message")"
							case "${arg3,,}" in
								list)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Lists any known meta dat associated with your account."
									;;
								add)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Adds a string of meta data to your account. Format is: \"SET META ADD foo=bar\""
									;;
								del|delete|remove)
									echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Removes a string of meta data from your account. Note that wild cards are not accepted, the string must be an exact match. Format is: \"SET META DEL foo=bar\""
									;;
								*)
									echo "(${arg1,,})->(${arg2,,}) => Allows you to handle meta data associated with your account. Usually this data is utilized by modules (i.e. the Twitch.tv module [See modules/twitch.sh]). Any applicable modules should tell you the proper format to add meta data with in their help topic."
									;;
							esac
							;;
						removeacct|removeaccount)
							echo "(${arg1,,})->(${arg2,,}) => Begins the two-step removal process of a registered account. Format is: \"SET REMOVEACCT\". To cancel an account removal prior to the second step, use: \"SET REMOVEACCT cancel\""
							;;
						*)
							echo "(${arg1,,}) => Allows you to set certain items related to your account. Sub-commands are: Password, Clones, AllowedHost, Meta, RemoveAcct, RemoveAccount"
							;;
					esac
					;;
				*)
					if egrep -q "^modForm=(.*\"${arg1,,}\".*)$" var/.mods/*.sh; then
						helpFile="$(egrep "^modForm=(.*\"${arg1,,}\".*)$" var/.mods/*.sh /dev/null)"
						helpFile="${helpFile%%:*}"
						helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
						helpLine="${helpLine#modHelp=\"}"
						helpLine="${helpLine%\"}"
						echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
					elif -e "var/.mods/${arg1,,}.sh"; then
						helpFile="var/.mods/${arg1,,}.sh"
						helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
						helpLine="${helpLine#modHelp=\"}"
						helpLine="${helpLine%\"}"
						echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
					elif -e "var/.mods/${arg1,,}"; then
						helpFile="var/.mods/${arg1,,}"
						helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
						helpLine="${helpLine#modHelp=\"}"
						helpLine="${helpLine%\"}"
						echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
					else
						echo "No such help topic available"
					fi
					;;
			esac
		else
			# Could it match case insensitive?
			if egrep -q "^modForm=(.*\"${arg1}\".*)$" var/.mods/*.sh; then
				helpFile="$(egrep "^modForm=(.*\"${arg1}\".*)$" var/.mods/*.sh /dev/null)"
				helpFile="${helpFile%%:*}"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			elif [ -e "var/.mods/${arg1}.sh" ]; then
				helpFile="var/.mods/${arg1}.sh"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			elif [ -e "var/.mods/${arg1}" ]; then
				helpFile="var/.mods/${arg1}"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			else
				echo "No such help topic available"
			fi
		fi
	;;
	mod)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="M"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				modCom="$(awk '{print $5}' <<<"$message")"
				unset modComItem
				case "${modCom,,}" in
					status)
						modComItem="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
						modComItem=(${modComItem})
						for arrItem in ${modComItem[@]}; do
							if ! echo "$arrItem" | egrep -q "\.sh$"; then
								arrItem="${arrItem}.sh"
							fi
							if [ -z "$arrItem" ]; then
								echo "This command requires a parameter (module name)"
							elif [ -e "var/.mods/${arrItem}" ]; then
								echo "${arrItem} is loaded"
							else
								echo "${arrItem} is not loaded"
							fi
						done
					;;
					load)
						modComItem="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
						modComItem=(${modComItem})
						for arrItem in ${modComItem[@]}; do
							if ! echo "$arrItem" | egrep -q "\.sh$"; then
								arrItem="${arrItem}.sh"
							fi
							if [ -e "var/.mods/${arrItem}" ]; then
								echo "${arrItem} is already loaded. Do you mean reload, or unload?"
							elif [ -e "modules/${arrItem}" ]; then
								cp "modules/${arrItem}" "var/.mods/${arrItem}"
								echo "modules/${arrItem} loaded"
							elif [ -e "contrib/${arrItem}" ]; then
								cp "contrib/${arrItem}" "var/.mods/${arrItem}"
								echo "contrib/${arrItem} loaded"
							else
								echo "${arrItem} does not appear to exist in \"modules/\" or \"contrib/\". Remember, on unix based file systems, case sensitivity matters!"
							fi
						done
					;;
					unload)
						modComItem="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
						modComItem=(${modComItem})
						for arrItem in ${modComItem[@]}; do
							if ! echo "$arrItem" | egrep -q "\.sh$"; then
								arrItem="${arrItem}.sh"
							fi
							if [ -e "var/.mods/${arrItem}" ]; then
								rm "var/.mods/${arrItem}"
								if [ -e "var/.mods/${arrItem}" ]; then
									echo "Unable to unload ${arrItem}!"
								else
									echo "${arrItem} unloaded"
								fi
							else
								echo "${arrItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
							fi
						done
					;;
					reload)
						modComItem="$(read -r one two three four five rest <<<"$message"; echo "$rest")"
						modComItem=(${modComItem})
						for arrItem in ${modComItem[@]}; do
							if ! echo "$arrItem" | egrep -q "\.sh$"; then
								arrItem="${arrItem}.sh"
							fi
							if [ -e "var/.mods/${arrItem}" ]; then
								rm "var/.mods/${arrItem}"
								if [ -e "var/.mods/${arrItem}" ]; then
									echo "Unable to unload ${arrItem}!"
								else
									echo "${arrItem} unloaded"
									if [ -e "modules/${arrItem}" ]; then
										cp "modules/${arrItem}" "var/.mods/${arrItem}"
										echo "modules/${arrItem} loaded"
									elif [ -e "contrib/${arrItem}" ]; then
										cp "contrib/${arrItem}" "var/.mods/${arrItem}"
										echo "contrib/${arrItem} loaded"
									else
										echo "Unable to load ${arrItem}!"
									fi
								fi
							else
								echo "${arrItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
							fi
						done
					;;
					reloadall)
						for modComItem in var/.mods/*.sh; do
							modComItem="${modComItem##*/}"
							rm "var/.mods/${modComItem}"
							if [ -e "var/.mods/${modComItem}" ]; then
								echo "Unable to unload ${modComItem}!"
							else
								echo "${modComItem} unloaded"
								if [ -e "modules/${modComItem}" ]; then
									cp "modules/${modComItem}" "var/.mods/${modComItem}"
									echo "modules/${modComItem} loaded"
								elif [ -e "contrib/${modComItem}" ]; then
									cp "contrib/${modComItem}" "var/.mods/${modComItem}"
									echo "contrib/${modComItem} loaded"
								else
									echo "Unable to load ${modComItem}!"
								fi
							fi
						done
					;;
					list)
						unset modArr
						modLineArr=0
						while read modLine; do
							modArr[ $modLineArr ]="${modLine}"
							(( modLineArr++ ))
						done < <(ls -1 var/.mods/)
						echo "${modArr[@]}"
					;;
					*)
						echo "Invalid command. Valid options: Status, Load, Unload, Reload, ReloadAll, List"
					;;
				esac
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
	;;
	*)
		for i in var/.mods/*.sh; do
			if fgrep -i -q "modHook=\"Prefix\"" "$i"; then
				modArr="$(fgrep "modForm=" "$i")"
				modArr="${modArr#modForm=}"
				modArr="${modArr#(}"
				modArr="${modArr%)}"
				if echo "$modArr" | fgrep -q "\"$com\""; then
					./${i} "$message"
				fi
			fi
		done
	;;
esac

}

# Check to see if we're ignoring this user or not
ignoreUser="0"
while read i; do
	if [ "$(egrep -c "$i" <<<"${senderFull}")" -eq "1" ]; then
		ignoreUser="1"
	fi
done < var/ignore.db

if [ "$ignoreUser" -eq "0" ]; then

isPm="0"
if [ "$(fgrep -c "$senderTarget" <<< "$nick")" -eq "1" ]; then
	# It's a PM. We should assume we're being addressed in the same manner as commands.
	senderTarget="$senderNick"
	isPm="1"
fi

case "$(echo "$message" | awk '{print $2}')" in
	JOIN) 
		;;
	KICK)
		;;
	NOTICE)
		;;
	PRIVMSG)
		# This is a ${comPrefix} addressed command
		if [ "$(echo "$message" | awk '{print $4}' | cut -b 2)" == "${comPrefix}" ]; then
			isCom="1"
			com="$(awk '{print $4}' <<<"$message")"
			com="${com,,}"
			com="${com:2}"
		# This is a command beginning with ${nick}: ${nick}; or ${nick},
		elif [[ "$(awk '{print $4}' <<<"$message")" == ":${nick}"?([:;,]) ]]; then
			isCom="1"
			message="$(sed -E "s/:${nick}[:;,]? //" <<<"$message")"
			com="$(awk '{print $4}' <<<"$message")"
			com="${com,,}"
		# It's a PM
		elif [ "$isPm" -eq "1" ]; then
			isCom="1"
			com="$(awk '{print $4}' <<<"$message")"
			com="${com,,}"
			com="${com:1}"
		else
			isCom="0"
		fi
		if [ "$isCom" -eq "1" ]; then
			comExec;
		else	
			for i in var/.mods/*.sh; do
				if fgrep -i -q "modHook=\"Format\"" "$i"; then
					pattern="$(fgrep "modForm=" "$i")"
					pattern="${pattern#modForm=}"
					pattern="${pattern#(\"}"
					pattern="${pattern%\")}"
					caseSensitive="$(fgrep "modFormCase=" "$i")"
					caseSensitive="${caseSensitive#modFormCase=}"
					caseSensitive="${caseSensitive#\"}"
					caseSensitive="${caseSensitive%\"}"
					if echo "$caseSensitive" | grep -i -q "Yes"; then
						if echo "$message" | egrep -q "$pattern"; then
							./${i} "$message"
						fi
					else
						if echo "$message" | egrep -i -q "$pattern"; then
							./${i} "$message"
						fi
					fi
				fi
			done
		fi
		;;
	QUIT)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			sed -i "/${senderUser}@${senderHost}/d" var/.admins
		fi
		;;
	MODE)
		;;
	PART) 
		;;
	NICK)
		;;
	WALLOPS)
		;;
	TOPIC)
		;;
	INVITE)
		;;
	*)
		echo "[DEBUG - ${0}] $message"
		echo "$(date -R) [${0}] ${message}" >> ${dataDir}/$(<var/bot.pid).debug
		;;
esac
fi

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
	login)
		if [ "$isPm" -eq "1" ]; then
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
			if [ "$loggedIn" -eq "0" ]; then
				lUser="$(awk '{print $5}' <<<"$message")"
				lPass="$(echo "$message" | awk '{print $6}')"
				lPass="$(echo "$lPass" | md5sum | awk '{print $1}')"
				lPass2="$(echo "$lPass" | md5sum | awk '{print $1}')"
				lHash="${lPass}${lPass2}"
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
					ignoreHost="$(awk '{print $6}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
					case "$(awk '{print $5}' <<<"$message" | tr "[:upper:]" "[:lower:]")" in
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
		if [ "$isPm" -eq "1" ]; then
			echo "(login) => Logs you in to the bot"
			echo "(logout) => Logs you out of the bot"
			echo "(flogout) => Force logs another user out of the bot"
			echo "(admins) => Lists the currently logged in admins"
			echo "(join) => I'll join a channel"
			echo "(part) => I'll part a channel"
			echo "(speak|say) => I'll speak a message in a channel"
			echo "(action|do) => I'll do a /ME in a channel"
			echo "(nick) => I'll change nicks"
			echo "(ignore) => I'll ignore a regular expression n!u@h mask"
			echo "(status) => I'll give a status report"
			echo "(die|quit|exit) => I'll quit IRC and shut down"
			echo "(restart) => I'll restart, quitting IRC and joining a new spawn"
			echo "(uptime) => I'll give you an uptime report"
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
				line="$(fgrep "modHelp" "$i")"
				line="${line#*\"}"
				line="${line%\"}"
				echo "(${file}) => ${line}"
			done
		else
			echo "Please use this command in a private message to prevent unnecessary channel spamming"
		fi
	;;
	mod)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "1" ]; then
			reqFlag="M"
			if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				modCom="$(awk '{print $5}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
				case "$modCom" in
					status)
						modComItem="$(awk '{print $6}' <<<"$message")"
						if ! echo "$modComItem" | egrep -q "\.sh$"; then
							modComItem="${modComItem}.sh"
						fi
						if [ -e "var/.mods/${modComItem}" ]; then
							echo "${modComItem} is loaded"
						else
							echo "${modComItem} is not loaded"
						fi
					;;
					load)
						modComItem="$(awk '{print $6}' <<<"$message")"
						if ! echo "$modComItem" | egrep -q "\.sh$"; then
							modComItem="${modComItem}.sh"
						fi
						if [ -e "var/.mods/${modComItem}" ]; then
							echo "${modComItem} is already loaded. Do you mean reload, or unload?"
						elif [ -e "modules/${modComItem}" ]; then
							cp "modules/${modComItem}" "var/.mods/${modComItem}"
							echo "modules/${modComItem} loaded"
						elif [ -e "contrib/${modComItem}" ]; then
							cp "contrib/${modComItem}" "var/.mods/${modComItem}"
							echo "contrib/${modComItem} loaded"
						else
							echo "${modComItem} does not appear to exist in \"modules/\" or \"contrib/\". Remember, on unix based file systems, case sensitivity matters!"
						fi
					;;
					unload)
						modComItem="$(awk '{print $6}' <<<"$message")"
						if ! echo "$modComItem" | egrep -q "\.sh$"; then
							modComItem="${modComItem}.sh"
						fi
						if [ -e "var/.mods/${modComItem}" ]; then
							rm "var/.mods/${modComItem}"
							if [ -e "var/.mods/${modComItem}" ]; then
								echo "Unable to unload ${modComItem}!"
							else
								echo "${modComItem} unloaded"
							fi
						else
							echo "${modComItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
						fi
					;;
					reload)
						modComItem="$(awk '{print $6}' <<<"$message")"
						if ! echo "$modComItem" | egrep -q "\.sh$"; then
							modComItem="${modComItem}.sh"
						fi
						if [ -e "var/.mods/${modComItem}" ]; then
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
						else
							echo "${modComItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
						fi
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
			com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
			com="${com:2}"
		# This is a command beginning with ${nick}: ${nick}; or ${nick},
		elif [[ "$(awk '{print $4}' <<<"$message")" == ":${nick}"?([:;,]) ]]; then
			isCom="1"
			message="$(sed -E "s/:${nick}[:;,]? //" <<<"$message")"
			com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
		# It's a PM
		elif [ "$isPm" -eq "1" ]; then
			isCom="1"
			com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
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

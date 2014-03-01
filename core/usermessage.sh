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
		# Commented out for development purposes, uncomment for production and remove if true line
		#if [ "$isPm" -eq "1" ]; then
		if true; then
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
			if [ "$loggedIn" -eq "0" ]; then
				lUser="$(awk '{print $5}' <<<"$message")"
				lPass="$(echo "$message" | awk '{print $6}')"
				lPass="$(echo "$lPass" | md5sum | awk '{print $1}')"
				lPass2="$(echo "$lPass" | md5sum | awk '{print $1}')"
				lHash="${lPass}${lPass2}"
				if egrep -v "(^#|^\$)" admins.conf | fgrep -q "user=\"${lUser}\""; then
					# User exists
					if egrep -v "(^#|^\$)" admins.conf | fgrep -A 3 "user=\"${lUser}\"" | fgrep -q "pass=\"${lHash}\""; then
						if egrep -q "^${lUser}" var/.admins; then
							# User is already logged in. How many clones are they allowed?
							numClonesAllowed="$(egrep -v "(^#|^\$)" admins.conf | fgrep -A 3 "user=\"${lUser}" | egrep "clones=\"[0-9]+\"")"
							numClonesAllowed="${numClonesAllowed%\"}"
							numClonesAllowed="${numClonesAllowed#*\"}"
							numClones="$(egrep "^${lUser}" var/.admins | awk '{print $2}')"
							if [ "$numClones" -lt "$numClonesAllowed" ]; then
								userLine="$(egrep "^${lUser}" var/.admins)"
								numClones="$(( $numClones + 1 ))"
								allowedFlags="$(awk '{print $3}' <<<"$userLine")"
								existingHosts="$(read -r one two three rest <<<"$userLine"; echo "$rest")"
								sed -i "/^${lHost}/d" var/.admins
								echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> var/.admins
								echo "Successfully logged in."
							else
								echo "User ${lUser} is already logged in with the maximum number of alloted clones."
							fi
						else
							# Password matches user
							allowedFlags="$(egrep -v "(^#|^\$)" admins.conf | fgrep -A 3 "user=\"${lUser}\"" | egrep "flags=\"[a-z|A-Z]+\"")"
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
			echo "This command cannot be used in public channels."
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
	*)
		# We should check for external command hooks from modules here
		./core/modhook.sh "$message"
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

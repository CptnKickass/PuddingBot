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
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
		if [ "$loggedIn" -eq "0" ]; then
			lUser="$(echo "$message" | awk '{print $5}')"
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
							echo "${senderNick}: Successfully logged in."
						else
							echo "User ${lUser} is already logged in with the maximum number of alloted clones."
						fi
					else
						# Password matches user
						allowedFlags="$(egrep -v "(^#|^\$)" admins.conf | fgrep -A 3 "user=\"${lUser}\"" | egrep "flags=\"[a-z|A-Z]+\"")"
						allowedFlags="${allowedFlags%\"}"
						allowedFlags="${allowedFlags#*\"}"
						echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> var/.admins
						echo "${senderNick}: Successfully logged in."
					fi
				else
					# Password does not match user
					echo "Invalid login"
					echo "${senderNick}: Invalid login."
				fi
			else
				# No such user
				echo "${senderNick}: Invalid login."
			fi
		else
			loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
			echo "Already logged in as ${loggedInUser}"
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
				if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
					echo "This command requires a parameter"
				elif [ "$(echo "$message" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(echo "$message" | awk '{print $5}') does not appear to be a valid channel"
				else
					echo "JOIN $(echo "$message" | awk '{print $5}')" >> $output
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
				if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
					echo "This command requires a parameter"
				elif [ "$(echo "$message" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
					echo "$(echo "$message" | awk '{print $5}') does not appear to be a valid channel"
				else
					echo "PART $(echo "$message" | awk '{print $5}') :Leaving channel per ${senderNick}" >> $output
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
				echo "I am $nick, currently connected to $server (${actualServer} on ${networkName}) via port $port. I am hosted on $(uname -n). My PID is $$. My owner is $owner ($ownerEmail)."
			else
				echo "I am $nick. My owner is $owner ($ownerEmail)"
			fi
		else
			echo "I am $nick. My owner is $owner ($ownerEmail)"
		fi
	;;
	uptime)
		timeDiff="$(( $(date +%s) - $startTime ))"
		days=$((timeDiff/60/60/24))
		hours=$((timeDiff/60/60%24))
		minutes=$((timeDiff/60%60))
		seconds=$((timeDiff%60))
		echo "Uptime: $days days, ${hours} hours, ${minutes} minutes, ${seconds} seconds"
	;;
esac

}

if [ "$senderTarget" = "$nick" ]; then
	# It's a PM. 
	senderTarget="$senderNick"
fi

case "$(echo "$message" | awk '{print $2}')" in
	JOIN) 
		;;
	KICK)
		;;
	NOTICE)
		;;
	PRIVMSG)
		if [ "$(echo "$message" | awk '{print $4}' | cut -b 2)" == "${comPrefix}" ]; then
			isCom="1"
			com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
			com="${com:2}"
		elif [[ "$(awk '{print $4}' <<<"$message")" == ":${nick}"?([:;,]) ]]; then
			isCom="1"
			message="$(sed -E "s/:${nick}[:;,]? //" <<<"$message")"
			com="$(awk '{print $4}' <<<"$message" | tr "[:upper:]" "[:lower:]")"
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
		echo "[DEBUG-usermessage.sh] $message"
		echo "$(date) | Received unknown message level 3: ${message}" >> ${dataDir}/$$.debug
		;;
esac

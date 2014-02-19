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

# Core commands
comExec () {
com="$(echo "$message" | awk '{print $4}' | tr "[:upper:]" "[:lower:]")"
com="${com:2}"
case "$com" in
	join)
	if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
		echo "This command requires a parameter"
	elif [ "$(echo "$msg" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
		echo "$(echo "$msg" | awk '{print $5}') does not appear to be a valid channel"
	else
		echo "JOIN $(echo "$msg" | awk '{print $5}')"
		echo "Joined $(echo "$msg" | awk '{print $5}')"
	fi
	;;
	part)
	if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
		echo "This command requires a parameter"
	elif [ "$(echo "$msg" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
		echo "$(echo "$msg" | awk '{print $5}') does not appear to be a valid channel"
	else
		echo "PART $(echo "$msg" | awk '{print $5}')"
		echo "Left $(echo "$msg" | awk '{print $5}')"
	fi
	;;
	status)
		echo "I am $nick, currently connected to $server (${actualServer:1} on ${networkName}) via port $port. I am hosted on $(uname -n). My PID is $$. My owner is $owner ($ownerEmail)."
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
		senderTarget="$(echo "$senderTarget" | sed "s/\://")"
		;;
	KICK)
		;;
	NOTICE)
		;;
	PRIVMSG)
		if [ "$(echo "$message" | awk '{print $4}' | cut -b 2)" == "${comPrefix}" ]; then
			comExec;
		fi
		;;
	QUIT)
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
		echo "$(date) | Received unknown message level 3: ${message}" >> ${dataDir}/$$.debug
		;;
esac

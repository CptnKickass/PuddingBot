#!/usr/bin/env bash

# Check dependencies
deps=("nc" "touch")
for i in ${deps[@]}; do
	if ! command -v ${i} > /dev/null 2>&1; then
		echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
		exit 1 
	fi
done

# Load admins into the core
if [ -e "admins.conf" ]; then
	echo "Loading admins into bot"
else
	echo "Unable to locate bot admins config!"
	exit 1
fi

# Load variables into the core
if [ -e "var/.conf" ]; then
	echo "Loading variables into bot"
	source var/.conf
	#rm -f var/.conf
else
	echo "Unable to locate bot config!"
	exit 1
fi

# Load modules
if [ -e "var/.mods" ]; then
	echo "Loading modules into bot"
	if [ -d "core/.mods" ]; then
		rm -rf core/.mods
		mkdir core/.mods
	fi
	<var/.mods | while read line; do
		cp modules/${line} core/.mods
	done
	source core/modhook.sh
	#rm -f var/.mods
fi

# We need these to be boolean instead of blank
fullCon="0"
readMemo="0"
nickPassSent="0"
inArr="0"
# Convert some variables to boolean

# So we can know what our uptime is
startTime="$(date +%s)"

# Functions
inArray() {
# When passing items to this to see if they're in the array or not,
# the format should be:
# inArray "${itemToBeCheck}" "${arrayToCheck}"
# If it is in the array, it'll return the boolean of inArr=1.
local n=$1 h
shift
for h; do
	if [[ $n = "$h" ]]; then
		inArr="1"
	else
		inArr="0"
	fi
done
}

parseOutput () {
unset outArr
while IFS= read -rn256 -d '' outArr[i++]; do :; done <<< "$out"
}

echo "Creating datafile"
# Create the file that will be the messages going out to the server
touch "$output"
if [ -n "$serverpass" ]; then
		echo "NICK ${nick}" >> $output
		echo "USER $ident +iwx * :${gecos}" >> $output
		echo "PASS $serverpass" >> $output
	else
		echo "NICK $nick" >> $output
		echo "USER $ident +iwx * :${gecos}" >> $output
fi

echo "Connecting to IRC server"
# This is where the initial connection is spawned
tail -f "$output" | nc "$server" "$port" | while read message
do
	# Unset the previous output message
	unset out
	# Remote the ^M control character at the end of each line
	message="${message%}"
	echo "$message"
	# ${msgArr[@]} array will contain all input
	msgArr=("${msgArr[@]}" "${message}")
	if [ "$logIn" -eq "1" ]; then
		# This is where messages should be parsed for logging
		echo "Place holder"
	fi
	# The incoming messages should be in one of the following formats:
	# :${botNick} (Bot setting modes on itself)
	# :n!u@h (Another client)
	# :${server} (The IRCd server)
	# PING (PING's from the IRCd server)
	if [[ "$message" == "PING"* ]]; then
		# The message is a PING
		echo "PONG${message#PING}" >> $output
	elif [ "$(echo "$message" | awk '{print $1}')" == ":${nick}" ]; then
		# The bot is changing modes on itself
		./core/botmodechange.sh "$message"
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "1" ]; then
		# The message matches an n!u@h mask
		#./core/usermessage.sh "$message"
		senderTarget="$(echo "$message" | awk '{print $3}')"
		senderAction="$(echo "$message" | awk '{print $2}')"
		senderFull="$(echo "$message" | awk '{print $1}')"
		senderFull="${senderFull#:}"
		senderNick="${senderFull%!*}"
		senderUser="${senderFull#*!}"
		senderUser="${senderUser%@*}"
		senderHost="${senderFull#*@}"
		
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
					com="$(echo "$message" | awk '{print $4}' | tr "[:upper:]" "[:lower:]")"
					com="${com:2}"
					case "$com" in
						login)
							inArray "${senderUser}@${senderHost}" "${admins[@]}"
							if [ "$inArr" -eq "0" ]; then
								lUser="$(echo "$message" | awk '{print $5}')"
								lPass="$(echo "$message" | awk '{print $6}')"
								lPass="$(echo "$lPass" | md5sum | awk '{print $1}')"
								lPass2="$(echo "$lPass" | md5sum | awk '{print $1}')"
								lHash="${lPass}${lPass2}"
								if egrep -v "(^#|^\$)" admins.conf | fgrep -q "user=\"${lUser}\""; then
									# User exists
									if egrep -v "(^#|^\$)" admins.conf | fgrep -A 1 "user=\"${lUser}\"" | tail -n 1 | fgrep -q "pass=\"${lHash}\""; then
										# Password matches user
										admins=("${senderUser}@${senderHost}")
										echo "PRIVMSG $senderTarget :Successfully logged in" >> $output
										echo "PRIVMSG $senderTarget :\${admins[@]}: ${admins[@]}" >> $output
									else
										# Password does not match user
										echo "PRIVMSG $senderTarget :Invalid login" >> $output
									fi
								else
									# No such user
									echo "PRIVMSG $senderTarget :Invalid login" >> $output
								fi
							else
								echo "PRIVMSG $senderTarget :Already logged in" >> $output
							fi
						;;
						logout)
							inArray "${senderUser}@${senderHost}" "${admins[@]}"
							if [ "$inArr" -eq "0" ]; then
								echo "PRIVMSG $senderTarget :You are not logged in" >> $output
							else
								admins=("${admins[@]/${senderUser}@${senderHost}/}")
								echo "PRIVMSG $senderTarget :\${admins[@]}: ${admins[@]}" >> $output
							fi
						;;
						join)
						if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
							echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
						elif [ "$(echo "$message" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
							echo "$(echo "$message" | awk '{print $5}') does not appear to be a valid channel" >> $output
						else
							echo "JOIN $(echo "$message" | awk '{print $5}')" >> $output
							echo "PRIVMSG $senderTarget :Joined $(echo "$message" | awk '{print $5}')" >> $output
						fi
						;;
						part)
						if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
							echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
						elif [ "$(echo "$message" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
							echo "$(echo "$message" | awk '{print $5}') does not appear to be a valid channel" >> $output
						else
							echo "PART $(echo "$message" | awk '{print $5}')" >> $output
							echo "PRIVMSG $senderTarget :Left $(echo "$message" | awk '{print $5}')" >> $output
						fi
						;;
						status)
							echo "PRIVMSG $senderTarget :I am $nick, currently connected to $server (${actualServer:1} on ${networkName}) via port $port. I am hosted on $(uname -n). My PID is $$. My owner is $owner ($ownerEmail)." >> $output
						;;
						uptime)
							timeDiff="$(( $(date +%s) - $startTime ))"
							days=$((timeDiff/60/60/24))
							hours=$((timeDiff/60/60%24))
							minutes=$((timeDiff/60%60))
							seconds=$((timeDiff%60))
							echo "PRIVMSG $senderTarget :Uptime: $days days, ${hours} hours, ${minutes} minutes, ${seconds} seconds" >> $output
						;;
					esac
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
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "0" ]; then
		# The message does not match an n!u@h mask, and should be a server
		out="$(./core/servermessage.sh "$message")"
		if [ -n "$out" ]; then
			echo "$out" >> $output
		fi
	else
		# This should never be reached, but exists for debug purposes
		echo "$(date -R): $message" >> $$.debug
	fi
done

# We shouldn't ever break out of the above loop. If we do, something went wrong.
rm -f "$output"
exit 255

# This is the CTCP character, commented out for copy/paste use as needed.
# PRIVMSG goose :VERSION


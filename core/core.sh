#!/usr/bin/env bash

# Load variables into the core
egrep -v "^#" "pudding.conf" | egrep -v "^loadMod" | while read line; do
	line
done

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

# Create the pipe that will be the messages going out to the server
mkfifo "$output"
# This needs to be a one liner that outputs to two lines, for the sake
# of the pipe only letting in one line at a time.
if [ -n "$serverpass" ]; then
		echo -e "NICK $nick\nUSER $ident +iwx * :${gecos}\nPASS $serverpass" >> $output
	else
		echo -e "NICK $nick\nUSER $ident +iwx * :${gecos}" >> $output 
fi

# This is where the initial connection is spawned
tail -f $output | nc $server $port | while read message 
do
	# Remote the ^M control character at the end of each line
	message="${message%}"
	if [ "$logInput" -eq "1" ]; then
		# This is where messages should be parsed for logging
	fi
	# The incoming messages should be in one of the following formats:
	# :${botNick} (Bot setting modes on itself)
	# :n!u@h (Another client)
	# :${server} (The IRCd server)
	# PING (PING's from the IRCd server)
	if [[ "$message" == "PING"* ]]; then
		# The message is a PING
		echo "PONG${message#PING}" >> $output;;
	elif [[ "$(echo "$message" | awk '{print $1}')" == ":${botNick}" ]]; then
		# The bot is changing modes on itself
		./botmodechange.sh
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "1" ]; then
		# The message matches an n!u@h mask
		./usermessage.sh
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "0" ]; then
		# The message does not match an n!u@h mask, and should be a server
		./servermessage.sh
	else
		# This should never be reached, but exists for debug purposes
		echo "$(date -R): $message" >> $$.debug
	fi

##############################################################
##############################################################
##############################################################
##############################################################
##############################################################

	if [ -z "$actualServer" ]; then
	else
		if [ "$nickPassSent" -eq "1" ]; then
			# Let's sleep for a few seconds, to allow NS to change our host
			#sleep 3
			nickPassSent="0"
		fi
		# Now $actualServer is defined, so we can filter out messages from the server, versus everyone else.
		if [ "$(echo "$message" | awk '{print $1}' | egrep -c "^${actualServer}$")" -eq "1" ]; then
			# Sender is actually the server I'm connected to
			case "$(echo "$message" | awk '{print $2}')" in
					
			esac
		elif [ "$(echo "$message" | awk '{print $1}' | grep -c ":${nick}")" -eq "1" ]; then
			# I am the sender. This is the server forcing me to do things.
			if [ "$(echo "$message" | awk '{print $2}' | egrep -c "(MODE|JOIN|PART)")" -eq "0" ]; then
				echo "$(date) | Received unknown message level 2: ${message}" >> ${dataDir}/$$.debug
			fi
		elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^\:.*\!.*\@.*$")" -eq "1" ]; then
			# Sender matches n!u@h, and is therefore a person.
			senderNick="$(echo "$message" | awk '{print $1}' | sed -E "s/:(.*)\!.*\@.*/\1/")"
			senderUser="$(echo "$message" | awk '{print $1}' | sed -E "s/:.*\!(.*)\@.*/\1/")"
			senderHost="$(echo "$message" | awk '{print $1}' | sed -E "s/:.*\!.*\@(.*)/\1/")"
			senderFull="$(echo "$message" | awk '{print $1}' | sed "s/^://")"
			senderAction="$(echo "$message" | awk '{print $2}')"
			senderTarget="$(echo "$message" | awk '{print $3}')"
			senderIsAdmin="0"
			inArray "$senderNick" "${admins[@]}"
			if [ "$senderTarget" = "$nick" ]; then
				# It's a PM. 
				senderTarget="$senderNick"
			fi
			isCk="0"
			isCk="$(echo "$message" | egrep -c "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*")"
			if [ "$isCk" -ge "1" ]; then
				echo "$message" | egrep -o "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*" | while read ckUrl; do
					fixedUrl="$(echo "$ckUrl" | sed "s/.*ck\.net/https:\/\/captain-kickass\.net/i" | sed "s/.*sf\.net/http:\/\/snofox\.net/i")"
					echo "PRIVMSG $senderTarget :[URL] $fixedUrl" >> $output
				done
			fi
			isFox="$(echo "$message" | fgrep -c -i "what does the fox say?")"
			if [ "$isFox" -eq "1" ]; then
				if [ -z "$foxResponseNum" ]; then
					foxResponseNum="1"
				elif [ "$foxResponseNum" -eq "14" ]; then
					foxResponseNum="1"
				fi
				case $foxResponseNum in
					1) foxResponse="Ring-ding-ding-ding-dingeringeding!";;
					2) foxResponse="Gering-ding-ding-ding-dingeringeding!";;
					3) foxResponse="Wa-pa-pa-pa-pa-pa-pow!";;
					4) foxResponse="Hatee-hatee-hatee-ho!";;
					5) foxResponse="Joff-tchoff-tchoffo-tchoffo-tchoff!";;
					6) foxResponse="Tchoff-tchoff-tchoffo-tchoffo-tchoff!";;
					7) foxResponse="Jacha-chacha-chacha-chow!";;
					8) foxResponse="Chacha-chacha-chacha-chow!";;
					9) foxResponse="Fraka-kaka-kaka-kaka-kow!";;
					10) foxResponse="A-hee-ahee ha-hee!";;
					11) foxResponse="Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!";;
					12) foxResponse="Bay-budabud-dum-bam!";;
					13) foxResponse="Abay-ba-da bum-bum bay-do!";;
				esac
				foxResponseNum="$(( $foxResponseNum + 1 ))"
				echo "PRIVMSG $senderTarget :${foxResponse}" >> $output
			fi
			containsURL="0"
			containsURL="$(echo "$message" | egrep -c "http(s?):\/\/[^ \"\(\)\<\>]*")"
			if [ "$containsURL" -ge "1" ] && [ ! "$senderNick" == "Pudding" ] && [ "$senderIsAdmin" -eq "1" ]; then
				echo "$message" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | while read messageURL; do
					unset locationIsTrue
					unset pageTitle
					unset pageDest
					reqFullCurl="0"
					# Zero means the location is true, no redirect to the destination
					urlCurlContentHeader="$(curl -A 'Pudding' -m 5 -k -s -L -I "$messageURL")"
					httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
					if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "405")" -eq "1" ]; then
						reqFullCurl="1"
						urlCurlContentHeader="$(curl -A 'Pudding' -m 5 -k -s -L -o /dev/null -D - "$messageURL")"
						httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
					fi
					locationIsTrue="$(echo "$urlCurlContentHeader" | grep -c "Location:")"
					contentType="$(echo "$urlCurlContentHeader" | egrep -i "Content[ |-]Type:" | tail -n 1)"
					if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "200")" -eq "1" ]; then
						if [ "$(echo "$contentType" | fgrep -c "text/html")" -eq "1" ]; then
							pageTitle="$(curl -A 'Pudding' -m 5 -k -s -L "$messageURL" | awk -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' | sed -e 's/^[ \t]*//')"
							if [ -z "$pageTitle" ]; then
								pageTitle="[Unable to obtain page title]"
							else
								pageTitle="$(echo "$pageTitle" | w3m -dump -T text/html | tr '\n' ' ')"
							fi
						else
							pageTitle="${contentType}"
						fi
						if [ "$locationIsTrue" -ne "0" ]; then
							if [ "$requireFullCurl" -eq "1" ]; then
								pageDest="$(curl -A 'Pudding' -m 5 -k -s -L -o /dev/null -D - "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
							else
								pageDest="$(curl -A 'Pudding' -m 5 -k -s -L -I "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
							fi
						else
							pageDest="$messageURL"
						fi
						if [ -z "$pageDest" ]; then
							pageDest="[Error: Connection timed out]"
						fi
						if [ "$(echo "$pageDest" | egrep -c "^http(s)?://(www\.)?youtube\.com/")" -eq "1" ]; then
							vidId="${pageDest#*v=}"
							vidId="${vidId:0:11}"
							vidInfo="$(curl -A 'Pudding' -m 5 -k -s -L "http://gdata.youtube.com/feeds/api/videos/${vidId}")"
							vidSecs="$(echo "$vidInfo" | fgrep "yt:duration")"
							vidSecs="${vidSecs#*yt:duration seconds=\'}"
							vidSecs="${vidSecs%%\'*}"
							vidHours=$((vidSecs/60/60%24))
							vidMinutes=$((vidSecs/60%60))
							vidSeconds=$((vidSecs%60))
							if [ "$(echo "$vidSeconds" | egrep -c "^[0-9]$")" -eq "1" ]; then
								vidSeconds="0${vidSeconds}"
							fi
							if [ "$vidHours" -ne "0" ] && [ "$vidMinutes" -ne "0" ]; then
								pageTitle="${pageTitle} [${vidHours}:${vidMinutes}:${vidSeconds}]"
							elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -ne "0" ]; then
								pageTitle="${pageTitle} [${vidMinutes}:${vidSeconds}]"
							elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -eq "0" ]; then
								pageTitle="${pageTitle} [0:${vidSeconds}]"
							fi
						fi
						if [ "$locationIsTrue" -eq "0" ] && [ -n "$pageTitle" ]; then
							echo "PRIVMSG $senderTarget :[URL] $pageTitle" >> $output
						elif [ "$locationIsTrue" -ne "0" ] && [ -n "$pageTitle" ]; then
							echo "PRIVMSG $senderTarget :[URL] $pageTitle - Destination: ${pageDest}" >> $output
						fi
					else
						if [ -n "$httpResponseCode" ]; then
							echo "PRIVMSG $senderTarget :[URL] $httpResponseCode" >> $output
						fi
					fi
				done
			fi
			case "$(echo "$message" | awk '{print $2}')" in
				JOIN) 
					senderTarget="$(echo "$senderTarget" | sed "s/\://")"
					if [ "$senderIsAdmin" -eq "0" ]; then
						# Joining is not an admin
						if [ "$(echo "$message" | awk '{print $3}')" == ":#foxden" ]; then
							admins=("${admins[@]}" "${senderNick}")
						fi
					fi;;
				KICK)
					;;
				NOTICE)
					;;
				PRIVMSG)
					if [ "$senderIsAdmin" -eq "1" ]; then
						isCommand=$(echo "$message" | awk '{print $4}' | cut -b 2 | grep -c "${comPrefix}")
						isSed=$(read -r one two three rest <<<"$message"; echo "$rest" | sed "s/^://" | egrep -c "^s\/(.*)\/(.*)\/(i|g|ig)?$")
						if [ "$isCommand" -eq "1" ]; then
							runCommand
						elif [ "$isSed" -eq "1" ]; then
							sedCom="$(echo "$message" | egrep -o -i "s\/.*\/.*\/(i|g|ig)?")"
							sedItem="${sedCom#s/}"
							sedItem="${sedItem%/*/*}"
							prevLine="$(fgrep "PRIVMSG" "${input}" | fgrep "${sedItem}" | tail -n 2 | head -n 1)"
							prevSend="$(echo "$prevLine" | awk '{print $1}' | sed "s/!.*//" | sed "s/^://")"
							line="$(read -r one two three rest <<<"${prevLine}"; echo "$rest" | sed "s/^://")"
							if [ -n "$line" ]; then
								lineFixed="$(echo "$line" | sed "${sedCom}")"
								echo "PRIVMSG $senderTarget :[FTFY] <${prevSend}> $lineFixed" >> $output
							fi
						fi
					fi
					;;
				QUIT)
					if [ "$senderIsAdmin" -eq "1" ]; then
						admins=( ${admins[@]/${senderNick}/} )
					fi
					;;
				MODE) ;;
				PART) 
					if [ "$(echo "$message" | awk '{print $3}')" == "#foxden" ]; then
						if [ "$senderIsAdmin" -eq "1" ]; then
							admins=( ${admins[@]/${senderNick}/} )
						fi
					fi
					;;
				NICK)
					if [ "$senderIsAdmin" -eq "1" ]; then
						newNick="$(echo "$message" | awk '{print $3}' | sed "s/^://")"
						admins=( ${admins[@]/${senderNick}/} )
						admins=("${admins[@]}" "${newNick}")
					fi
					;;
				WALLOPS)
					processWallops;;
				TOPIC)
					;;
				INVITE)
					;;
				*)
					echo "$(date) | Received unknown message level 3: ${message}" >> ${dataDir}/$$.debug
					;;
			esac
		else
			# Sender isn't our server or a person. It's probably a remote server.
			case "$message" in
				PING*)
					echo "PONG${message#PING}" >> $output ;;
				*)
					case "$(echo "$message" | awk '{print $2}')" in
						NOTICE)
							processSnotice
							;;
						WALLOPS)
							processWallops
							;;
						MODE)
							# A remote server is setting a mode
							;;
						*)
							echo "$(date) | Received unknown message level 4: ${message}" >> ${dataDir}/$$.debug
							;;
					esac
					;;
			esac
		fi
	fi
done

# We escaped the above loop?
rm -f "$output" "$input"
exit 0

# This is the CTCP character, commented out for copy/paste use as needed.
# PRIVMSG goose :VERSION



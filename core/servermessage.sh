source var/.conf
message="$@"
case "$(echo "$message" | awk '{print $2}')" in
# 001 is the welcome message
001)
	fullCon="1"
	networkName="$(sed -E "s/.*Welcome to the (.*) Internet Relay Chat Network*/\1/i" <<<"$message")"
	# TODO FIX THIS BROKEN ASS LINE! ^^
	echo "networkName=\"${networkName}\"" >> var/.status
	actualServer="$(awk '{print $1}' <<<"$message")"
	actualServer="${actualServer#:}"
	echo "actualServer=\"${actualServer}\"" >> var/.status
	;;
# 002 is the "Your host is" reply
002)
	;;
# 003 is the "Server Creation Date" reply
003)
	;;
# 004 is the VERSION reply
004)
	;;
# 005 is the "I support" reply
005)
	;;
# 008 are the server notice masks
008)
	;;
# 015 is the MAP reply
015)
	;;
# 017 is the end of MAP reply
017)
	;;
# 219 is end of STATS report
219)
	;;
# 249 lists the currently online opers
249)
	;;
# 250 is the highest global connections count
250)
	;;
# 251 is the initial LUSERS reply
251)
	;;
# 252 is the LUSERS reply of IRC operators online
252)
	;;
# 253 is the LUSERS reply of number of connections
253)
	;;
# 254 is the LUSERS reply to the number of channels formed
254)
	;;
# 255 is the LUSERS reply for information to local connections
255)
	;;
# 265 is the local users count
265)
	;;
# 266 is the global users count
266)
	;;
# 331 is when no topic is set
331)
	;;
# 332 is a channel's topic
332)
	;;
# 333 is who set a channel's topic and the timestamp
333)
	;;
# 353 is a /NAMES list
353)
	;;
# 366 is the end of a /NAMES list
366)
	;;
# 372 is part of the MOTD
372)
	;;
# 375 is the start of the MOTD
375)
	if [ -n "$operId" ] && [ -n "$operPass" ]; then
		echo "OPER $operId $operPass"
		if [ -n "$operModes" ]; then
			echo "MODE $nick $operModes" >> $output
		fi
	fi
	if [ -n "$nickPass" ]; then
		echo "PRIVMSG NickServ :identify $nickPass" >> $output
		nickPassSent="1"
	fi
	for item in ${channels[*]}; do
		echo "JOIN $item" >> $output
	done
	if [ -n "$lastCom" ]; then
		echo "$lastCom" >> $output
	fi
	;;
# 376 Signifies end of MOTD numeric
376)
	;;
# 381 means we're opered up
381)
	;;
# 396 is a hostname change
396)
	;;
# 401 is a "No such recipient" error
401)
	;;
# 404 is a cannot send to channel
404)
	;;
# 412 is no text to send
412)
	;;
# Server is setting a mode
MODE)
	;;
# It's a snotice
NOTICE)
	;;
WALLOPS)
	;;
*)
	echo "[DEBUG-servermessage.sh] $message"
	echo "$(date -R): $message" >> $$.debug
	;;
esac

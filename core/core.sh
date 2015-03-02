#!/usr/bin/env bash

# Check dependencies
deps=("nc" "touch")
for i in "${deps[@]}"; do
	if ! command -v ${i} > /dev/null 2>&1; then
		echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
		exit 1 
	fi
done

# Load admins into the core
if [ -d "users" ]; then
	echo "Located users directory..."
else
	echo "Unable to locate users directory. Creating..."
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
fi

# Setup file for user checks
if [ -e "var/.admins" ]; then
	rm -f var/.admins
fi
touch var/.admins

# Setup file for status checks
if [ -e "var/.status" ]; then
	rm -f var/.status
fi
touch var/.status

# Setup file for ignore list
if [ ! -e "var/ignore.db" ]; then
	touch var/ignore.db
fi

echo "$$" > var/bot.pid

# We need these to be boolean instead of blank
fullCon="0"
nickPassSent="0"
inArr="0"
# So we can know what our uptime is
echo "startTime=\"$(date +%s)\"" >> var/.status

# Functions
inArray() {
# When passing items to this to see if they're in the array or not,
# the format should be:
# inArray "${itemToBeCheck}" "${arrayToCheck[@]}"
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
if [ "$isHelp" -ne "0" ]; then
	outAct="NOTICE"
	senderTarget="${senderNick}"
elif [ "$isCtcp" -ne "0" ]; then
	outAct="NOTICE"
else
	outAct="PRIVMSG"
fi
if [[ "$(awk '{print $2}' <<<"${message}")" == "PRIVMSG" ]]; then
	directOut="0"
	msgInArr=(${message})
	if [[ "${msgInArr[@]:(-2):1}" == ">" ]]; then
		if ! egrep -q "^(#|&)" <<<"${msgInArr[@]:(-1):1}"; then
			senderTarget="${msgInArr[@]:(-1):1}"
			outA="${senderNick} wants you to know: ${outArr[@]}"
			outArr=("${outA}")
		fi
	elif [[ "${msgInArr[@]:(-2):1}" == "|" ]]; then
		directOut="2"
		outArr=("${msgInArr[@]:(-1):1}: ${outArr}")
	fi
fi
if [ "${#outArr[@]}" -ne "0" ]; then
	unset sendArr
	for line in "${outArr[@]}"; do
		while IFS= read -rn350 -d '' sendArr[i++]; do :; done <<< "${line}"
	done
	unset outArr
	for line in "${sendArr[@]}"; do
		if [ -n "$line" ] && ! [[ "${line}" == " " ]] && ! [[ "${line}" == "" ]]; then
			echo "${outAct} ${senderTarget} :${line}" >> $output
			sleep 0.25
		fi
	done
fi
}

echo "Creating datafile"
# This should be done with a pipe, but a flat file is easier to debug
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
while [ -e "$output" ]; do tail -f "$output" | nc "$server" "$port" | while read -r message
do
	# Unset the previous output message
	unset out
	# Remote the ^M control character at the end of each line
	message="${message%}"
	# msgArr will contain just the current line in a message
	unset msgArr
	msgArr=(${message})

	echo "${msgArr[@]}" >> "${input}"
	# ${allMsgArr[@]} array will contain all input
	allMsgArr+=("${message}")
	if [ "$logIn" -eq "1" ]; then
		# This is where messages should be parsed for logging
		echo "Place holder" > /dev/null
	fi
	# The incoming messages should be in one of the following formats:
	# :${nick} (Bot setting modes on itself)
	# :n!u@h (Another client)
	# :${server} (The IRCd server)
	# PING (PING's from the IRCd server)
	if [[ "${msgArr[0]}" == "PING" ]]; then
		# The message is a PING
		echo "PONG ${msgArr[1]}" >> $output
	elif [[ "${msgArr[0]}" == ":${nick}" ]]; then
		# The bot is changing modes on itself
		out="$(source ./core/botmodechange.sh "${msgArr[@]}")"
		if [ -n "$out" ]; then
			mapfile outArr <<<"$out"
		fi
	elif egrep -q "^:.*!.*@.*$" <<<"${msgArr[0]}"; then
		# The message matches an n!u@h mask
		senderTarget="${msgArr[2]}"
		senderAction="${msgArr[1]}"
		senderFull="${msgArr[0]}"
		senderFull="${senderFull#:}"
		senderNick="${senderFull%!*}"
		senderUser="${senderFull#*!}"
		senderUser="${senderUser%@*}"
		senderHost="${senderFull#*@}"
		isCtcp="$(egrep -ic ":(PING|VERSION|TIME|DATE)" <<<"${msgArr[3]}")" 
		isHelp="$(egrep -ic ":(!)?(${nick}[:;,]?)?help" <<<"${msgArr[@]:(3):2}")" 
		out="$(source ./core/usermessage.sh "${msgArr[@]}")"
		if [ "$(fgrep -c "$senderTarget" <<< "$nick")" -eq "1" ]; then
			senderTarget="$senderNick"
		fi
		if [ -n "$out" ]; then
			mapfile <<<"$out" outArr
		fi
	elif [[ "${msgArr[0]}" == "ERROR" ]]; then
		echo "Received error message: ${msgArr[@]}"
		if [ -e "$output" ]; then
			rm -f "$output" 
		fi
		if [ -e "${input}" ]; then
			rm -f "${input}"
		fi
		if [ -e "var/.admins" ]; then
			rm -f "var/.admins"
		fi
		if [ -e "var/.conf" ]; then
			rm -f "var/.conf"
		fi
		if [ -e "var/.mods" ]; then
			rm -rf "var/.mods"
		fi
		if [ -e "var/.status" ]; then
			rm -f "var/.status"
		fi
		if [ -e "var/bot.pid" ]; then
			rm -f "var/bot.pid"
		fi
		
		#exit 0
		kill $$
	elif ! egrep -q "^:.*!.*@.*$" <<<"${msgArr[0]}"; then
		# The message does not match an n!u@h mask, and should be a server
		out="$(source ./core/servermessage.sh "${msgArr[@]}")"
		if [ -n "$out" ]; then
			senderTarget="${channels[0]}"
			mapfile <<<"$out" outArr
		fi
	else
		# This should never be reached, but exists for debug purposes
		mapfile <<<"[DEBUG - ${0}] ${msgArr[@]}" outArr
		echo "$(date -R) [${0}] ${msgArr[@]}" >> $(<var/bot.pid).debug
	fi
	parseOutput;

	# Commented out to prevent wiping of output for debug purposes
	#echo "" > "$output"
done
done

# We've broken free of the above loop? We're exiting.
if [ -e "$output" ]; then
	rm -f "$output" 
fi
if [ -e "${input}" ]; then
	rm -f "${input}"
fi
if [ -e "var/.admins" ]; then
	rm -f "var/.admins"
fi
if [ -e "var/.conf" ]; then
	rm -f "var/.conf"
fi
if [ -e "var/.mods" ]; then
	rm -rf "var/.mods"
fi
if [ -e "var/.status" ]; then
	rm -f "var/.status"
fi
if [ -e "var/bot.pid" ]; then
	rm -f "var/bot.pid"
fi

#exit 0
kill $$

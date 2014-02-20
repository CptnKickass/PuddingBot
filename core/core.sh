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
if [ -e "admins.conf" ]; then
	echo "Loading admins into bot"
	if [ -e "var/.admins" ]; then
		rm -f var/.admins
	fi
	touch var/.admins
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

# Setup file for status checks
if [ -e "var/.status" ]; then
	rm -f var/.status
fi
touch var/.status

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
if [ "${#outArr[@]}" -ne "0" ]; then
	unset sendArr
	for line in "${outArr[@]}"; do
		while IFS= read -rn320 -d '' sendArr[i++]; do :; done <<< "${line}"
	done
	unset outArr
	for line in "${sendArr[@]}"; do
		echo "PRIVMSG ${senderTarget} :${line}" >> $output
		sleep 0.25
	done
fi
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
tail -f "$output" | nc "$server" "$port" | while read -r message
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
	# :${nick} (Bot setting modes on itself)
	# :n!u@h (Another client)
	# :${server} (The IRCd server)
	# PING (PING's from the IRCd server)
	if [[ "$message" == "PING"* ]]; then
		# The message is a PING
		echo "PONG${message#PING}" >> $output
	elif [ "$(echo "$message" | awk '{print $1}')" == ":${nick}" ]; then
		# The bot is changing modes on itself
		out="$(./core/botmodechange.sh "$message")"
		if [ -n "$out" ]; then
			mapfile outArr <<<"$out"
		fi
		echo "Place holder"
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "1" ]; then
		# The message matches an n!u@h mask
		senderTarget="$(echo "$message" | awk '{print $3}')"
		senderAction="$(echo "$message" | awk '{print $2}')"
		senderFull="$(echo "$message" | awk '{print $1}')"
		senderFull="${senderFull#:}"
		senderNick="${senderFull%!*}"
		senderUser="${senderFull#*!}"
		senderUser="${senderUser%@*}"
		senderHost="${senderFull#*@}"
		out="$(./core/usermessage.sh "$message")"
		if [ -n "$out" ]; then
			mapfile <<<"$out" outArr
		fi
	elif [ "$(echo "$message" | awk '{print $1}' | egrep -c "^:.*!.*@.*$")" -eq "0" ]; then
		# The message does not match an n!u@h mask, and should be a server
		out="$(./core/servermessage.sh "$message")"
		if [ -n "$out" ]; then
			mapfile <<<"$out" outArr
		fi
	else
		# This should never be reached, but exists for debug purposes
		mapfile <<<"[DEBUG-core.sh] $message" outArr
		echo "$(date -R): $message" >> $$.debug
	fi
	parseOutput;
done

# We shouldn't ever break out of the above loop. If we do, something went wrong.
rm -f "$output"
exit 255

# This is the CTCP character, commented out for copy/paste use as needed.
# PRIVMSG goose :VERSION


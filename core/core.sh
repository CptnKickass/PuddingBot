#!/usr/bin/env bash

# Check dependencies
deps=("nc" "mkfifo")
for i in ${deps[@]}; do
	if ! command -v ${i} > /dev/null 2>&1; then
		echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
		exit 1 
	fi
done

# Load variables into the core
if [ -e "../var/.conf" ]; then
	echo "Loading variables into bot."
	source ../var/.conf
	#rm -f ../var/.conf
else
	echo "Unable to locate bot config!"
	exit 1
fi

# Load modules
if [ -e "../var/.mods" ]; then
	echo "Loading moduels into bot."
	if [ -d ".mods" ]; then
		rm -rf .mods
		mkdir .mods
	fi
	<../var/.mods | while read line; do
		cp ../modules/${line} .mods
	done
	source modhook.sh
	#rm -f ../var/.mods
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

# Create the pipe that will be the messages going out to the server
mkfifo "$output"
# This needs to be a one liner that outputs to two lines, for the sake
# of the pipe only letting in one line at a time.
if [ -n "$serverpass" ]; then
		echo -e "NICK ${nick}\nUSER $ident +iwx * :${gecos}\nPASS $serverpass" >> $output
	else
		echo -e "NICK $nick\nUSER $ident +iwx * :${gecos}" >> $output 
fi

# This is where the initial connection is spawned
tail -f $output | nc $server $port | while read message; do
	# Remote the ^M control character at the end of each line
	message="${message%}"
	# ${msgArr[@]} array will contain all input
	msgArr=("${msgArr[@]}" "${message}")
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
		echo "PONG${message#PING}" >> $output
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
done

# We shouldn't ever break out of the above loop. If we do, something went wrong.
rm -f "$output"
exit 255

# This is the CTCP character, commented out for copy/paste use as needed.
# PRIVMSG goose :VERSION


#!/usr/bin/env bash

# Load variables into the core
if [ -e "var/.conf" ]; then
	echo "Loading variables into bot"
	source var/.conf
else
	echo "Unable to locate bot config!"
	exit 255
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
local n=${1} h
shift
for h; do
	if [[ ${n} = "${h}" ]]; then
		inArr="1"
	else
		inArr="0"
	fi
done
}

echo "Creating datafile"
# This should be done with a pipe, but a flat file is easier to debug
# Create the file that will be the messages going out to the server
touch "${output}"
if [ -n "${serverpass}" ]; then
		echo "NICK ${nick}" >> "${output}"
		echo "USER ${ident} +iwx * :${gecos}" >> "${output}"
		echo "PASS ${serverpass}" >> "${output}"
	else
		echo "NICK ${nick}" >> "${output}"
		echo "USER ${ident} +iwx * :${gecos}" >> "${output}"
fi

echo "Connecting to IRC server"
# This is where the initial connection is spawned
while [ -e "${output}" ]; do tail -f "${output}" | nc "${server}" "${port}" | while read -r message
do
	isHelp="0"
	isCtcp="0"
	# Remote the ^M control character at the end of each line
	message="${message%}"
	msgArr=(${message})

	echo "${msgArr[@]}" >> "${input}"
	# ${allMsgArr[@]} array will contain all input
	allMsgArr+=("${msgArr[@]}")
	if [ "${logIn}" -eq "1" ]; then
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
		echo "PONG ${msgArr[1]}" >> "${output}"
	elif [[ "${msgArr[0]}" == ":${nick}" ]]; then
		# The bot is changing modes on itself
		out="$(source ./bin/self/botmodechange.sh)"
		if [ -n "${out}" ]; then
			mapfile outArr <<<"${out}"
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

		out="$(source ./bin/user/usermessage.sh)"
		if [ "$(fgrep -c "${senderTarget}" <<< "${nick}")" -eq "1" ]; then
			senderTarget="${senderNick}"
		fi
		if [ -n "${out}" ]; then
			mapfile outArr <<<"${out}" 
		fi
	elif [[ "${msgArr[0]}" == "ERROR" ]]; then
		echo "Received error message: ${msgArr[@]}"
		if [ -e "${output}" ]; then
			#rm -f "${output}" 
			mv "${output}" "${output} - $(date)"
		fi
		if [ -e "${input}" ]; then
			#rm -f "${input}"
			mv "${input}" "${input} - $(date)"
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
			pid="$(<var/bot.pid)"
			rm -f "var/bot.pid"
		fi
		kill ${pid}
		exit 0
	elif ! egrep -q "^:.*!.*@.*$" <<<"${msgArr[0]}"; then
		# The message does not match an n!u@h mask, and should be a server
		out="$(source ./bin/server/servermessage.sh)"
		if [ -n "${out}" ]; then
			senderTarget="${channels[0]}"
			mapfile outArr <<<"${out}" 
		fi
	else
		# This should never be reached, but exists for debug purposes
		echo "$(date -R) [${0}] ${msgArr[@]}" >> $(<var/bot.pid).debug
	fi

	echo "outArr: ${outArr[@]}"

	if [ "${#outArr[@]}" -ne "0" ]; then
		source ./bin/core/parseoutput.sh
	fi

	# Wipe the output file
	#echo "" > "${output}"
done
done

# We've broken free of the above loop? We're exiting.
if [ -e "${output}" ]; then
	#rm -f "${output}" 
	mv "${output}" "${output} - $(date)"
fi
if [ -e "${input}" ]; then
	#rm -f "${input}"
	mv "${input}" "${input} - $(date)"
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
	pid="$(<var/bot.pid)"
	rm -f "var/bot.pid"
fi
kill ${pid}
exit 0

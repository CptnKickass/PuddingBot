#!/usr/bin/env bash

## Config
# Config options go here

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "$depFail" -eq "1" ]; then
			exit 1
		else
			echo "ok"
			exit 0
		fi
	else
		echo "ok"
		exit 0
	fi
fi

modHook="Prefix"
modForm=("seen")
modFormCase=""
modHelp="Checks to see the last time a user was seen"
modFlag="m"
msg="$@"
seenTarget="${msgArr[4]}"
#if [[ "${seenTarget,,}" == "${senderNick}" ]]; then
#	echo "Eat a dick ${senderNick}"
#	exit 0
#elif [[ "${seenTarget,,}" == "${nick,,}" ]]; then
#	echo "Eat a buffet of dicks ${senderNick}"
#	exit 0
#fi
# This method is preferred, but pisses off vim's syntax. So I'll use sed for debugging purposes.
#seenTarget="${seenTarget//\'/''}"
seenTarget="$(sed "s/'/''/g" <<<"${seenTarget}")"
sqlUserExists="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM seen WHERE nick = '${seenTarget}';")"
if [ -z "${sqlUserExists}" ]; then
	# Returned nothing. User does not exist.
	echo "I have no such record of anyone by the nick ${seenTarget}"
else
	# User does exist.
	lastSeenNuh="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT nuh FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenTime="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seen FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenSaid="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seensaid FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenSaidIn="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seensaidin FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	timeDiff="$(( $(date +%s) - ${lastSeenTime} ))"
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
	if [ "${days:0:1}" -ne "0" ]; then
		seenAgo="${days}, ${hours}, ${minutes}, ${seconds}"
	elif [ "${hours:0:1}" -ne "0" ]; then
		seenAgo="${hours}, ${minutes}, ${seconds}"
	elif [ "${minutes:0:1}" -ne "0" ]; then
		seenAgo="${minutes}, ${seconds}"
	else
		seenAgo="${seconds}"
	fi
	echo "${seenTarget} last seen ${seenAgo} ago (from \"${lastSeenNuh#*!}\"), saying \"${lastSeenSaid}\" in ${lastSeenSaidIn}"
fi
exit 0

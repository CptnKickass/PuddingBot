#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("tail")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=()
	if [[ "${#apis[@]}" -ne "0" ]]; then
		if [[ -e "api.conf" ]]; then
			for i in "${apis[@]}"; do
				val="$(egrep "^${i}" "api.conf")"
				val="${val#${i}=\"}"
				val="${val%\"}"
				if [[ -z "${val}" ]]; then
					echo -e "Missing api key \"${red}${i}${reset}\"! Exiting."
					apiFail="1"
				fi
			done
		else
			path="$(pwd)"
			path="${path##*/}"
			path="./${path}/${0##*/}"
			echo "Unable to locate \"api.conf\"!"
			echo "(Are you running the dependency check from the main directory?)"
			echo "(ex: ${path} --dep-check)"
			exit 255
		fi
	fi
	if [[ "${sqlSupport}" -eq "0" ]]; then
		echo "MySQL support required for this module, but not enabled!"
		depFail="1"
	fi
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

modHook="Prefix"
modForm=("seen")
modFormCase=""
modHelp="Checks to see the last time a user was seen"
modFlag="m"
msg="$@"
seenTarget="${msgArr[4]}"
if [[ "${seenTarget,,}" == "${senderNick}" ]]; then
	echo "Go play in traffic"
	exit 0
elif [[ "${seenTarget,,}" == "${nick,,}" ]]; then
	echo "Eat a buffet of dicks, ${senderNick}"
	exit 0
fi
# This method is preferred, but pisses off vim's syntax. So I'll use sed for debugging purposes.
#seenTarget="${seenTarget//\'/''}"
seenTarget="$(sed "s/'/''/g" <<<"${seenTarget}")"
sqlUserExists="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM seen WHERE nick = '${seenTarget}';")"
if [[ -z "${sqlUserExists}" ]]; then
	# Returned nothing. User does not exist.
	echo "[Seen] I have no such record of anyone by the nick ${seenTarget}"
else
	# User does exist.
	lastSeenNuh="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT nuh FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenTime="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seen FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenSaid="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seensaid FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	lastSeenSaidIn="$(mysql -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT seensaidin FROM seen WHERE nick = '${seenTarget}';" | tail -n 1)"
	timeDiff="$(( $(date +%s) - ${lastSeenTime} ))"
	days="$((timeDiff/60/60/24))"
	if [[ "${days}" -eq "1" ]]; then
		days="${days} day"
	else
		days="${days} days"
	fi
	hours="$((timeDiff/60/60%24))"
	if [[ "${hours}" -eq "1" ]]; then
		hours="${hours} hour"
	else
		hours="${hours} hours"
	fi
	minutes="$((timeDiff/60%60))"
	if [[ "${minutes}" -eq "1" ]]; then
		minutes="${minutes} minute"
	else
		minutes="${minutes} minutes"
	fi
	seconds="$((timeDiff%60))"
	if [[ "${seconds}" -eq "1" ]]; then
		seconds="${seconds} second"
	else
		seconds="${seconds} seconds"
	fi
	if [[ "${days:0:1}" -ne "0" ]]; then
		seenAgo="${days}, ${hours}, ${minutes}, ${seconds}"
	elif [[ "${hours:0:1}" -ne "0" ]]; then
		seenAgo="${hours}, ${minutes}, ${seconds}"
	elif [[ "${minutes:0:1}" -ne "0" ]]; then
		seenAgo="${minutes}, ${seconds}"
	else
		seenAgo="${seconds}"
	fi
	echo "[Seen] ${seenTarget} last seen ${seenAgo} ago (from \"${lastSeenNuh#*!}\"), saying \"${lastSeenSaid}\" in ${lastSeenSaidIn}"
fi

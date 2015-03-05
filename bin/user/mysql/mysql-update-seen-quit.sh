#!/usr/bin/env bash

if ! [[ "${senderNick}" == "${nick}" ]]; then
	# Escape the data
	unset sqlMsgArr
	sqlMsg="$(sed "s/'/''/g" <<<"${msgArr[@]}")"
	sqlMsg="$(sed 's/\\/\\\\/g' <<<"${sqlMsg}")"
	sqlMsgArr=(${sqlMsg})
	sqlNuh="${senderFull}"
	sqlNick="${senderNick}"
	sqlSeen="$(date +%s)"
	sqlSeenQuit="${sqlMsgArr[@]:2}"
	sqlSeenQuit="${sqlSeenQuit#:}"
	sqlSeenSaid="QUIT: ${sqlSeenQuit}"
	sqlSeenSaidIn="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT seensaidin FROM seen WHERE nick = '${sqlNick}';")"
	if [ -z "${sqlSeenSaidIn}" ]; then
		sqlSeenSaidIn="[Unknown]"
	fi
	# Is the user already in the database?
	sqlUserExists="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM seen WHERE nick = '${sqlNick}';")"
	if [ -z "${sqlUserExists}" ]; then
		# Returned nothing. User does not exist. Let's add them.
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO seen VALUES ('${sqlNuh}','${sqlNick}','${sqlSeen}','${sqlSeenSaid}','${sqlSeenSaidIn}');" 
	else
		# User does exist. Let's update them.
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE seen SET seen = '${sqlSeen}', seensaid = '${sqlSeenSaid}', seensaidin = '${sqlSeenSaidIn}', nuh = '${sqlNuh}' WHERE nick = '${sqlNick}';"
	fi
fi

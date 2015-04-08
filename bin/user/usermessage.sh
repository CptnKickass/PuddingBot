#!/usr/bin/env bash
# For simplicities sake, I'll keep all commands in this function
comExec () {
case "${com}" in
	register)
		source ./bin/user/commands/register.sh
	;;
	set)
		source ./bin/user/commands/set.sh
	;;
	login)
		source ./bin/user/commands/login.sh
	;;
	logout)
		source ./bin/user/commands/logout.sh
	;;
	flogout)
		source ./bin/user/commands/forcelogout.sh
	;;
	admins)
		source ./bin/user/commands/admins.sh
	;;
	join)
		source ./bin/user/commands/join.sh
	;;
	part)
		source ./bin/user/commands/part.sh
	;;
	speak|say)
		source ./bin/user/commands/speak.sh
	;;
	action|do)
		source ./bin/user/commands/action.sh
	;;
	nick)
		source ./bin/user/commands/nickchange.sh
	;;
	ignore)
		source ./bin/user/commands/ignore.sh
	;;
	status)
		source ./bin/user/commands/status.sh
	;;
	die|quit|exit)
		source ./bin/user/commands/quit.sh
	;;
	restart)
		source ./bin/user/commands/restart.sh
	;;
	uptime)
		source ./bin/user/commands/uptime.sh
	;;
	help)
		source ./bin/user/commands/help.sh
	;;
	mod)
		source ./bin/user/commands/mod.sh
	;;
	quiet|silence|lobotomy|mute)
		source ./bin/user/commands/silence.sh
	;;
	unquiet|unsilence|unlobotomy|unmute)
		source ./bin/user/commands/unsilence.sh
	;;
	rehash|reload)
		source ./bin/user/commands/rehash.sh
	;;
	*)
		modMatch="0"
		for i in var/.mods/*.sh; do
			if egrep -i -q "^modHook=\"Prefix\"" "${i}"; then
				modArr="$(egrep "^modForm=" "${i}")"
				modArr="${modArr#modForm=}"
				modArr="${modArr#(}"
				modArr="${modArr%)}"
				modArr=("${modArr}")
				for q in "${modArr[@]}"; do
					if fgrep -q "\"${com}\"" <<<"${q}"; then
						modMatch="1"
						source ./${i} 
					fi
				done
			fi
		done
		if [[ "${modMatch}" -eq "0" ]]; then
			source ./bin/core/factoid.sh 
		fi
	;;
esac

}

# Check to see if we're ignoring this user or not
ignoreUser="0"
while read i; do
	if egrep -q "${i}" <<<"${senderFull}"; then
		ignoreUser="1"
	fi
done < var/ignore.db

if [[ "${ignoreUser}" -eq "0" ]]; then
	isPm="0"
	if [[ "${senderTarget,,}" == "${nick,,}" ]]; then
		# It's a PM. We should assume we're being addressed in the same manner as commands.
		senderTarget="${senderNick}"
		isPm="1"
	fi
	
	case "${msgArr[1]^^}" in
		JOIN) 
			# MySQL Seen Stuff
			if [[ "${sqlSupport}" -eq "1" ]]; then
				source ./bin/usr/mysql-update-seen-join.sh
			fi

			# Someone changed modes? Time for a new names!
			echo "NAMES ${senderTarget}" >> "${output}"
			;;
		KICK)
			# Someone changed modes? Time for a new names!
			echo "NAMES ${senderTarget}" >> "${output}"
			;;
		NOTICE)
			;;
		PRIVMSG)
			# MySQL Seen Stuff
			if [[ "${sqlSupport}" -eq "1" ]]; then
				source ./bin/user/mysql/mysql-update-seen-privmsg.sh
				factMessage="${msgArr[@]}"
			fi
			# Now that user's data is updated.
			# Let's check for karma
			if egrep -q "^.*:([[:alnum:]]|[[:punct:]])+(\+\+|--)$" <<<"${msgArr[@]}"; then
				if [[ "${sqlSupport}" -eq "1" ]]; then
					source ./bin/user/mysql/mysql-karma.sh
				fi
			# This is a ${comPrefix} addressed command
			elif [[ "${msgArr[3]:0:2}" == ":${comPrefix}" ]]; then
				isCom="1"
				com="${msgArr[3]}"
				com="${com,,}"
				com="${com:2}"
			# This is a command beginning with ${nick}: ${nick}; or ${nick},
			elif [[ ${msgArr[3],,} =~ ^":${nick,,}"[[:punct:]]?$ ]]; then
				isCom="1"
				msgStr="${msgArr[@]}"
				msgStr="${msgStr/${msgArr[3]} /:${comPrefix}}"
				msgArr=(${msgStr})
				com="${msgArr[3]}"
				com="${com,,}"
				com="${com:2}"
			# It's a PM
			elif [[ "${isPm}" -eq "1" ]]; then
				# Is it a CTCP?
				if egrep -iq ":(PING|VERSION|TIME|DATE)" <<<"${msgArr[3]}"; then
					isCom="0"
					source ./bin/user/ctcp.sh
				else
					isCom="1"
					com="${msgArr[3]}"
					com="${com,,}"
					com="${com:1}"
				fi
			else
				isCom="0"
			fi
			if [[ "${isCom}" -eq "1" ]]; then
				comExec;
			else	
				modMatch="0"
				for i in var/.mods/*.sh; do
					if egrep -i -q "^modHook=\"Format\"" "${i}"; then
						modArr="$(egrep "^modForm=" "${i}")"
						modArr="${modArr#modForm=}"
						modArr="${modArr#(}"
						modArr="${modArr%)}"
						tmp="$(mktemp)"
						sed -E 's/" "/\n/g' <<<"${modArr}" > "${tmp}"
						sed -i "s/^\"//g" "${tmp}"
						sed -i "s/\"$//g" "${tmp}"
						unset modArr
						readarray -t modArr < "${tmp}"
						rm "${tmp}"
						for q in "${modArr[@]}"; do
							q="${q#\"}"
							q="${q%\"}"
							if egrep -q -i "^modFromCase=\"Yes\"" "${i}"; then
								if egrep -q "\"${q}\"" <<<"${msgArr[@]}"; then
									modMatch="1"
									source ./${i} 
								fi
							else
								if egrep -i -q "${q}" <<<"${msgArr[@]}"; then
									modMatch="1"
									source ./${i}
								fi
							fi
						done
					fi
				done
				if [[ "${modMatch}" -eq "0" ]]; then
					source ./bin/core/factoid.sh 
				fi
			fi
			;;
		QUIT)
			loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
			if [[ "${loggedIn}" -eq "1" ]]; then
				sed -i "/${senderUser}@${senderHost}/d" "var/.admins"
			fi
			# MySQL Seen Stuff
			if [[ "${sqlSupport}" -eq "1" ]]; then
				source ./bin/user/mysql/mysql-update-seen-quit.sh
			fi
			# Someone changed modes? Time for a new names!
			echo "NAMES ${senderTarget}" >> "${output}"
			;;
		MODE)
			# Someone changed modes? Time for a new names!
			echo "NAMES ${senderTarget}" >> "${output}"
			;;
		PART) 
			# MySQL Seen Stuff
			if [[ "${sqlSupport}" -eq "1" ]]; then
				source ./bin/user/mysql/mysql-update-seen-part.sh
			fi
			# Someone changed modes? Time for a new names!
			echo "NAMES ${senderTarget}" >> "${output}"
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
			echo "$(date -R) [${0}] ${msgArr[@]}" >> ${dataDir}/$(<var/bot.pid).debug
			;;
	esac
elif  [[ "${senderNick,,}" == "grodt" ]]; then
	if [[ -e "var/.mods/grodt.sh" ]]; then
		source ./var/.mods/grodt.sh
	fi
fi

#!/usr/bin/env bash

# Escape the data
unset sqlMsgArr
sqlMsg="$(sed "s/'/''/g" <<<"${msgArr[@]}")"
sqlMsgArr=(${sqlMsg})
karmaTarget="${sqlMsgArr[3]}"
karmaTarget="${karmaTarget#:}"
karmaAction="${karmaTarget:(-2)}"
karmaTarget="${karmaTarget%++}"
karmaTarget="${karmaTarget%--}"
# No changing your own karma
if ! [[ "${karmaTarget,,}" == "${senderNick,,}" ]]; then
	karmaUserExists="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM karma WHERE nick = '${karmaTarget}';")"
	if [[ -z "${karmaUserExists}" ]]; then
		# Returned nothing. User does not exist. Let's add them.
		if [[ "${karmaAction}" == "++" ]]; then
			mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO karma VALUES ('${karmaTarget}','1');"
		elif [[ "${karmaAction}" == "--" ]]; then
			mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO karma VALUES ('${karmaTarget}','-1');"
		fi
	elif [[ "${karmaAction}" == "++" ]]; then
		oldKarma="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT value FROM karma WHERE nick = '${karmaTarget}';")"
		newKarma="$(( ${oldKarma} + 1 ))"
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE karma SET value = '${newKarma}' WHERE nick = '${karmaTarget}';"
	elif [[ "${karmaAction}" == "--" ]]; then
		oldKarma="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT value FROM karma WHERE nick = '${karmaTarget}';")"
		newKarma="$(( ${oldKarma} - 1 ))"
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE karma SET value = '${newKarma}' WHERE nick = '${karmaTarget}';"
	fi
else
	karmaUserExists="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM karma WHERE nick = '${karmaTarget}';")"
	if [[ -z "${karmaUserExists}" ]]; then
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO karma VALUES ('${karmaTarget}','-1');"
	else
		oldKarma="$(mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE puddingbot; SELECT value FROM karma WHERE nick = '${karmaTarget}';")"
		newKarma="$(( ${oldKarma} - 1 ))"
		mysql --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE karma SET value = '${newKarma}' WHERE nick = '${karmaTarget}';"
	fi
	
fi

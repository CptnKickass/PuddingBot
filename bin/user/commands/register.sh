#!/usr/bin/env bash

if [[ "${isPm}" -eq "1" ]]; then
	loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
	if [[ "${loggedIn}" -eq "0" ]]; then
		lUser="${msgArr[4]}"
		lPass="${msgArr[5]}"
		lHash="$(echo -n "${lPass}" | sha256sum | awk '{print $1}')"
		if [[ -z "${lUser}" ]]; then
			echo "You must provide a username. Format is: \"register USERNAME PASSWORD\""
		elif [[ -z "${lPass}" ]]; then
			echo "You must provide a password. Format is: \"register USERNAME PASSWORD\""
		fi
		if [[ -n "${lUser}" ]] && [[ -n "${lPass}" ]]; then
			if [[ -e "${userDir}/${lUser}.conf" ]]; then
				echo "That username has already been taken. Please choose another."
			else
				echo "user=\"${lUser}\"" > "${userDir}/${lUser}.conf"
				echo "pass=\"${lHash}\"" >> "${userDir}/${lUser}.conf"
				genFlags="$(egrep "^genFlags=" "${dataDir}/pudding.conf")"
				genFlags="${genFlags/genF/f}"
				echo "${genFlags}" >> "${userDir}/${lUser}.conf"
				echo "clones=\"3\"" >> "${userDir}/${lUser}.conf"
				genFlags="${genFlags%\"}"
				genFlags="${genFlags#*\"}"
				echo "${lUser} 1 ${genFlags} ${senderUser}@${senderHost}" >> var/.admins
				echo "Successfully registered and logged in with username \"${lUser}\" and password \"${lPass}\". Please note that your default alloted clones that can be logged in at once is 3. Please use: \"set clones N\" to change this, where \"N\" is your desired number of clones."
			fi
		fi
	else
		loggedInUser="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
		echo "You are already logged in as ${loggedInUser}."
	fi
else
	echo "Registration must be done in PM"
fi

#!/usr/bin/env bash

if [[ "${isPm}" -eq "1" ]]; then
	loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
	if [[ "${loggedIn}" -eq "0" ]]; then
		if [[ -z "${msgArr[6]}" ]]; then
			lUser="${msgArr[4]}"
			lPass="${msgArr[5]}"
			lHash="$(echo -n "${lPass}" | sha256sum | awk '{print $1}')"
		else
			lUser="${msgArr[5]}"
			lPass="${msgArr[6]}"
			lHash="$(echo -n "${lPass}" | sha256sum | awk '{print $1}')"
		fi
		if [[ -n "${lUser}" ]]; then
			if egrep -q "^user=\"${lUser}\"$" ${userDir}/*.conf; then
				matchFile="$(egrep "^user=\"${lUser}\"$" ${userDir}/*.conf /dev/null)"
				matchFile="${matchFile%%:*}"
				# User exists
				if fgrep -q "pass=\"${lHash}\"" "${matchFile}"; then
					if egrep -q "^${lUser}" "var/.admins"; then
						# User is already logged in. How many clones are they allowed?
						numClonesAllowed="$(egrep "clones=\"[0-9]+\"" "${matchFile}")"
						numClonesAllowed="${numClonesAllowed%\"}"
						numClonesAllowed="${numClonesAllowed#*\"}"
						numClones="$(egrep "^${lUser}" "var/.admins" | awk '{print $2}')"
						if [[ "${numClones}" -lt "${numClonesAllowed}" ]]; then
							# Less than their alloted number
							userLine="$(egrep "^${lUser}" "var/.admins")"
							numClones="$(( ${numClones} + 1 ))"
							allowedFlags="$(awk '{print $3}' <<<"${userLine}")"
							existingHosts="$(read -r one two three rest <<<"${userLine}"; echo "${rest}")"
							sed -i "/^${lHost}/d" "var/.admins"
							echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> "var/.admins"
							echo "Successfully logged in."
						else
							# Their alloted number
							echo "User ${lUser} is already logged in with the maximum number of alloted clones."
						fi
					else
						# Password matches user, and they don't have any clones logged in
						allowedFlags="$(egrep "flags=\"[a-z|A-Z]+\"" "${matchFile}")"
						allowedFlags="${allowedFlags%\"}"
						allowedFlags="${allowedFlags#*\"}"
						echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> "var/.admins"
						echo "Successfully logged in."
					fi
				else
					# Password does not match user
					echo "Invalid login."
				fi
			else
				# No such user
				echo "Invalid login."
			fi
		else
			if egrep -q "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null; then
				matchFile="$(egrep "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null)"
				matchFile="${matchFile%%:*}"
				lUser="$(egrep "^user=\"" "${matchFile}")"
				lUser="${lUser#*\"}"
				lUser="${lUser%\"}"
				# User exists and matches a known allowed host
				if egrep -q "^${lUser}" "var/.admins"; then
					# User is already logged in. How many clones are they allowed?
					numClonesAllowed="$(egrep "clones=\"[0-9]+\"" "${matchFile}")"
					numClonesAllowed="${numClonesAllowed%\"}"
					numClonesAllowed="${numClonesAllowed#*\"}"
					numClones="$(egrep "^${lUser}" "var/.admins" | awk '{print $2}')"
					if [[ "${numClones}" -lt "${numClonesAllowed}" ]]; then
						# Less than their alloted number
						userLine="$(egrep "^${lUser}" "var/.admins")"
						numClones="$(( ${numClones} + 1 ))"
						allowedFlags="$(awk '{print $3}' <<<"${userLine}")"
						existingHosts="$(read -r one two three rest <<<"${userLine}"; echo "${rest}")"
						sed -i "/^${lHost}/d" "var/.admins"
						echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> "var/.admins"
						echo "Successfully logged in as ${lUser}."
					else
						# Their alloted number
						echo "User ${lUser} is already logged in with the maximum number of alloted clones."
					fi
				else
					# Password matches user, and they don't have any clones logged in
					allowedFlags="$(egrep "flags=\"[a-z|A-Z]+\"" "${matchFile}")"
					allowedFlags="${allowedFlags%\"}"
					allowedFlags="${allowedFlags#*\"}"
					echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> "var/.admins"
					echo "Successfully logged in as ${lUser}."
				fi
			else
				# No such user
				echo "You are not using an authenticated host. Please log in with username and password."
			fi
		fi
	else
		loggedInUser="$(fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $1}')"
		echo "Already logged in as ${loggedInUser}."
	fi
else
	loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
	if [[ "${loggedIn}" -eq "0" ]]; then
		if egrep -q "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null; then
			matchFile="$(egrep "^allowedLoginHost=\"${senderUser}@${senderHost}\"$" ${userDir}/*.conf /dev/null)"
			matchFile="${matchFile%%:*}"
			lUser="$(egrep "^user=\"" "${matchFile}")"
			lUser="${lUser#*\"}"
			lUser="${lUser%\"}"
			# User exists and matches a known allowed host
			if egrep -q "^${lUser}" "var/.admins"; then
				# User is already logged in. How many clones are they allowed?
				numClonesAllowed="$(egrep "clones=\"[0-9]+\"" "${matchFile}")"
				numClonesAllowed="${numClonesAllowed%\"}"
				numClonesAllowed="${numClonesAllowed#*\"}"
				numClones="$(egrep "^${lUser}" "var/.admins" | awk '{print $2}')"
				if [[ "${numClones}" -lt "${numClonesAllowed}" ]]; then
					# Less than their alloted number
					userLine="$(egrep "^${lUser}" "var/.admins")"
					numClones="$(( ${numClones} + 1 ))"
					allowedFlags="$(awk '{print $3}' <<<"${userLine}")"
					existingHosts="$(read -r one two three rest <<<"${userLine}"; echo "${rest}")"
					sed -i "/^${lHost}/d" "var/.admins"
					echo "${lUser} ${numClones} ${allowedFlags} ${senderUser}@${senderHost} ${existingHosts}" >> "var/.admins"
					echo "Successfully logged in as ${lUser}."
				else
					# Their alloted number
					echo "User ${lUser} is already logged in with the maximum number of alloted clones."
				fi
			else
				# Password matches user, and they don't have any clones logged in
				allowedFlags="$(egrep "flags=\"[a-z|A-Z]+\"" "${matchFile}")"
				allowedFlags="${allowedFlags%\"}"
				allowedFlags="${allowedFlags#*\"}"
				echo "${lUser} 1 ${allowedFlags} ${senderUser}@${senderHost}" >> "var/.admins"
				echo "Successfully logged in as ${lUser}."
			fi
		else
			# No such user
			echo "You are not using an authenticated host. Please log in via PM."
		fi
	else
		loggedInUser="$(fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $1}')"
		echo "Already logged in as ${loggedInUser}."
	fi
fi

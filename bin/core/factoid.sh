#!/usr/bin/env bash

learnFact () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO factoids VALUES ('${factTrig}','${factType} ${factVal}','0','${senderFull}','$(date +%s)','${senderFull}','$(date +%s)','0','');" 
	echo "Ok, I'll remember ${factTrigOrig[@]} is ${factType} ${factValOrig}"
else
	# Factoid does exist.
	unset eFR
	readarray -t eFR <<<"$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';")"
	echo "But ${factTrigOrig[@]} is already ${eFR[@]}"
fi
}

learnAddtlFact () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]}"
else
	isLocked="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT locked FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	# Factoid does exist.
	if [[ "${isLocked}" -eq "0" ]]; then
		# Factoid does exist.
		unset eFR
		readarray -t eFR <<<"$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';")"
		factValMatches="0"
		for i in "${eFR[@]}"; do
			if [[ "${factType,,} ${factVal,,}" == "${i,,}" ]]; then
				factValMatches="1"
			fi
		done
		if [[ "${factValMatches}" -eq "0" ]]; then
			factNo="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT callno FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
			factCall="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT calledby FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
			mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO factoids VALUES ('${factTrig}','${factType} ${factVal}','0','${senderFull}','$(date +%s)','${senderFull}','$(date +%s)','${factNo}','${factCall}');" 
			echo "Ok, I'll remember ${factTrigOrig[@]} is also ${factType} ${factValOrig}"
		else
			echo "But I already knew that ${factTrigOrig[@]} is ${factType} ${factValOrig}"
		fi
	else
		echo "I can't forget ${factTrigOrig[@]}, it's locked!"
	fi
fi
}

lockFact () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]:1}"
else
	# Factoid does exist.
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE factoids SET locked = '1' WHERE id = '${factTrig}';"
	echo "Ok, I locked factoid ${factTrigOrig[@]:1}"
fi
}

unlockFact () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]:1}"
else
	# Factoid does exist.
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE factoids SET locked = '0' WHERE id = '${factTrig}';"
	echo "Ok, I unlocked factoid ${factTrigOrig[@]:1}"
fi
}

forgetFact () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]:1}"
else
	isLocked="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT locked FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	# Factoid does exist.
	if [[ "${isLocked}" -eq "0" ]]; then
		mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; DELETE FROM factoids WHERE id = '${factTrig}';"
		echo "Ok, I forgot ${factTrigOrig[@]:1}"
	else
		echo "I can't forget ${factTrigOrig[@]:1}, it's locked!"
	fi
fi
}

getFactInfo () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]:1}"
else
	factNum="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';" | wc -l)"
	factLocked="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT locked FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factMade="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT createdon FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factMadeBy="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT created FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factMod="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT updatedon FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factModBy="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT updated FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factCalled="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT callno FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factCalledBy="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT calledby FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	echo "${factTrigOrig[@]:1} was created on $(date -d @${factMade}) by ${factMadeBy%%!*} (${factMadeBy#*!}). It was last modified on $(date -d @${factMod}) by ${factModBy%%!*} (${factModBy#*!}). It has been called ${factCalled} times, most recently by ${factCalledBy%%!*} (${factCalledBy#*!}). It has ${factNum} possible replies."
fi
}

getLiteral () {
sqlFactExists="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT * FROM factoids WHERE id = '${factTrig}';")"
if [[ -z "${sqlFactExists}" ]]; then
	# Returned nothing. Factoid does not exist. Let's add it.
	echo "But I don't have any factoids for ${factTrigOrig[@]:1}"
else
	factVal="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';")"
	unset factVals
	readarray -t factVals <<<"${factVal}"
	factVal="$(printf '%s || ' "${factVals[@]}"; printf '\n')"
	factVal="${factVal% || }"
	echo "${factTrigOrig[@]:1} is literally: ${factVal}"
fi
}

callFact () {
factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
factVal="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';")"
unset factVals
readarray -t factVals <<<"${factVal}"
if [[ "${#factVals[@]}" -eq "0" ]]; then
	factTrig="${factTrigOrig[@]}"
	factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
	factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
	factVal="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT fact FROM factoids WHERE id = '${factTrig}';")"
	unset factVals
	readarray -t factVals <<<"${factVal}"
fi
if [[ "${#factVals[@]}" -ne "0" ]]; then
	factOut="${factVals[${RANDOM} % ${#factVals[@]} ]] }"
	repAct="$(awk '{print $1}' <<<"${factOut,,}")"
	repAct="${repAct#<}"
	repAct="${repAct%>}"
	if egrep -q -i "<sender(\^|,)?>" <<<"${factOut}"; then
		while read q; do
			q="${q#<}"
			q="${q%>}"
			case "${q,,}" in
				sender,)
				factOut="${factOut//<sender,>/${senderNick,,}}"
				;;
				sender^)
				factOut="${factOut//<sender^>/${senderNick^^}}"
				;;
				*)
				factOut="${factOut//<sender>/${senderNick}}"
				;;
			esac
		done < <(egrep -o -i "<sender(\^|,)?>" <<<"${factOut}")
	fi
	if egrep -q -i "<botnick(\^|,)?>" <<<"${factOut}"; then
		while read q; do
			q="${q#<}"
			q="${q%>}"
			case "${q,,}" in
				botnick,)
				factOut="${factOut//<botnick,>/${nick,,}}"
				;;
				botnick^)
				factOut="${factOut//<botnick^>/${nick^^}}"
				;;
				*)
				factOut="${factOut//<botnick>/${nick}}"
				;;
			esac
		done < <(egrep -o -i "<botnick(\^|,)?>" <<<"${factOut}")
	fi
	if egrep -q -i "<random(\^|,)?>" <<<"${factOut}"; then
		while read q; do
			getRandomNick;
			q="${q#<}"
			q="${q%>}"
			case "${q,,}" in
				random,)
				factOut="${factOut//<random,>/${randomNick,,}}"
				;;
				random^)
				factOut="${factOut//<random^>/${randomNick^^}}"
				;;
				*)
				factOut="${factOut//<random>/${randomNick}}"
				;;
			esac
		done < <(egrep -o -i "<random(\^|,)?>" <<<"${factOut}")
	fi
	case "${repAct}" in
		reply)
		echo "${factOut#*> }"
		;;
		action)
		echo "ACTION ${factOut#*> }"
		;;
	esac
	factCalled="$(mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; SELECT callno FROM factoids WHERE id = '${factTrig}' LIMIT 1;")"
	factCalled="$(( ${factCalled} + 1 ))"
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE factoids SET callno = '${factCalled}' WHERE id = '${factTrig}';"
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; UPDATE factoids SET calledby = '${senderFull}' WHERE id = '${factTrig}';"
fi
}

inArr=(${factMessage})

# Let's trim the first three useless items.
inArr=(${inArr[@]:3})

# We only need the message contents
msgTrim="${inArr[@]}"
msgTrim="${msgTrim#:}"
msgTrim="$(sed "s/IS/is/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/IS ALSO/is also/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<REPLY>/<reply>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<ACTION>/<action>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<SENDER>/<sender>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<SENDER,>/<sender,>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<SENDER^>/<sender^>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<BOTNICK>/<botnick>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<BOTNICK,>/<botnick,>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<BOTNICK^>/<botnick^>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<RANDOM>/<random>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<RANDOM,>/<random,>/i" <<<"${msgTrim}")"
msgTrim="$(sed "s/<RANDOM^>/<random^>/i" <<<"${msgTrim}")"

msgArr=(${msgTrim})
wasAddressed="0"
if [[ "${msgArr[0],,}" == "${nick,,}"* ]]; then
	wasAddressed="1"
	msgArr=(${msgArr[@]:1})
elif [[ "${msgArr[0],,}" == "${comPrefix}"* ]]; then
	msgArr[0]="${msgArr[0]#${comPrefix}}"
fi

msgTrim="${msgArr[@]}"
# Are we learning a new factoid?
if egrep -iq ".*is <(reply|action)>.*" <<<"${msgTrim}"; then
	# We're learning a new factoid!
	factTrig="${msgTrim%% is <*}"
	factTrigOrig=(${factTrig})
	factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
	factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
	factVal="${msgTrim#*>}"
	factVal="${factVal# }"
	factValOrig="${factVal}"
	factVal="$(sed "s/'/''/g" <<<"${factVal}")"
	factVal="$(sed 's/\\/\\\\/g' <<<"${factVal}")"
	factType="${msgTrim#*<}"
	factType="${factType%%>*}"
	factType="<${factType,,}>"
	learnFact;
elif egrep -iq ".*is also <(reply|action)>.*" <<<"${msgTrim}"; then 
	# We're appending an existing factoid!
	factTrig="${msgTrim%% is also <*}"
	factTrigOrig=(${factTrig})
	factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
	factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
	factVal="${msgTrim#*>}"
	factVal="${factVal# }"
	factValOrig="${factVal}"
	factVal="$(sed "s/'/''/g" <<<"${factVal}")"
	factVal="$(sed 's/\\/\\\\/g' <<<"${factVal}")"
	factType="${msgTrim#*<}"
	factType="${factType%%>*}"
	factType="<${factType,,}>"
	learnAddtlFact;
elif [[ "${wasAddressed}" -eq "1" ]] || [[ "${isPm}" -eq "1" ]]; then
	factTrig="${msgTrim,,}"
	factTrigOrig=(${factTrig})
	factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
	factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
	case "${msgArr[0],,}" in
		lock)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
		if [[ "${loggedIn}" -eq "1" ]]; then
			reqFlag="l"
			if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				target="${msgArr[1]}"
				if [[ -n "${target}" ]]; then
					factTrig="${factTrig#*lock }"
					lockFact;
				else
					echo "This command requires a parameter"
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
		;;
		unlock)
		loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
		if [[ "${loggedIn}" -eq "1" ]]; then
			reqFlag="l"
			if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
				target="${msgArr[1]}"
				if [[ -n "${target}" ]]; then
					factTrig="${factTrig#*unlock }"
					unlockFact;
				else
					echo "This command requires a parameter"
				fi
			else
				echo "You do not have sufficient permissions for this command"
			fi
		else
			echo "You must be logged in to use this command"
		fi
		;;
		forget)
		factTrig="${factTrig#*forget }"
		forgetFact;
		;;
		factinfo|info)
		factTrig="${factTrig#*info }"
		getFactInfo;
		;;
		literal)
		factTrig="${factTrig#*literal }"
		getLiteral;
		;;
		*)
		factTrig="${msgArr[@]}"
		callFact;
		;;
	esac
elif [[ -z "${factRe}" ]]; then
	factTrig="${msgTrim,,}"
	factTrigOrig=(${factTrig})
	factTrig="$(sed -E "s/[!|?|.|:]+$//g" <<<"${factTrig}")"
	callFact;
elif [[ "${msgTrim:(-1)}" =~ ${factRe} ]]; then
	factTrig="${msgTrim,,}"
	if [[ -n "${factRe}" ]] && [[ "${factTrig:(-1)}" =~ ${factRe} ]]; then
		factTrigOrig=(${factTrig})
		factTrig="$(sed -E "s/${factRe}+$//g" <<<"${factTrig}")"
	fi
	callFact;
fi

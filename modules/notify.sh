#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
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
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

modHook="Prefix"
modForm=("notify" "memo")
modFormCase=""
modHelp="Leaves a memo for a user"
modFlag="m"
loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
if [[ "${1,,}" == "--check" ]]; then
	if [[ -e "var/.notify" ]]; then
		n="0"
		unset del
		while read q; do
			q=(${q})
			if [[ "${q[0],,}" == "${senderNick,,}" ]]; then
				echo "[Notify] ${q[0]}: ${q[1]} left you this memo:"
				echo "[Notify] ${q[@]:2}"
				del="$(( ${n} + 1 ))"
				break
			fi
			(( n++ ))
		done < "var/.notify"
		if [[ -n "${del}" ]]; then
			sed -i "${del}d" "var/.notify"
		fi
	fi
else
	if [[ "${loggedIn}" -eq "1" ]]; then
		if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${modFlag}"; then
			target="${msgArr[4]}"
			memo=(${msgArr[@]:5})
			if [[ "${target,,}" == "me" ]]; then
				echo "[Notify] Isn't that a little redundant?"
				exit 0
			fi
			if [[ -z "${target}" ]]; then
				echo "[Notify] This command requires a target"
			elif [[ "${#memo[@]}" -eq "0" ]]; then
				echo "[Notify] You didn't give me a memo"
			else
				echo "[Notify] Ok, I'll give ${target} that memo the next time I see them"
				echo "${target} ${senderNick} ${memo[@]}" >> "var/.notify"
			fi
		else
			echo "[Notify] You do not have sufficient permissions for this command"
		fi
	else
		echo "[Notify] You must be logged in to use this command"
	fi
fi

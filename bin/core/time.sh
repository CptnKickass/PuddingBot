#!/usr/bin/env bash

currDay="$(egrep "^currDay=\"" "var/.status")"
currDay="${currDay#currDay=\"}"
currDay="${currDay%\"}"
if [[ -n "${currDay}" ]]; then
	if [[ "${currDay}" -ne "$(date +%d)" ]]; then
		source ./bin/core/log.sh --day
		sed -i "/^currDay=\"/d" "var/.status"
		echo "currDay=\"$(date +%d)\"" >> "var/.status"
	fi
else
	echo "currDay=\"$(date +%d)\"" >> "var/.status"
fi

if [[ "${idleTime}" -ne "0" ]]; then
	for chan in var/.last/*; do
		old="$(<${chan})"
		cur="$(date +%s)"
		if [[ "$(( ${cur} - ${old} ))" -ge "${idleTime}" ]]; then
			chan="${chan#var/.last/}"
			senderTarget="${chan}"
			readarray -t rand < "${idleLines}"
			rand=(${rand[${RANDOM} % ${#rand[@]} ]] })
			if egrep -q "\<random[^|,]?\>" <<<"${rand[@]}"; then
				getRandomNick;
				rand=(${rand[@]//<random>/${randomNick}})
				rand=(${rand[@]//<random^>/${randomNick^^}})
				rand=(${rand[@]//<random,>/${randomNick,,}})
			fi
			if [[ "${rand[0],,}" == "say" ]]; then
				out="${rand[@]:1}"
			else
				out="${rand[@]}" 
			fi
			mapfile outArr <<<"${out}"
			if [[ -e "var/.silence" ]]; then
			        unset outArr
			else
			        if [[ "${#outArr[@]}" -ne "0" ]]; then
			                source ./bin/core/parseoutput.sh
					echo "$(date +%s)" > "var/.last/${chan,,}"
			        fi
			fi
		fi
	done
fi

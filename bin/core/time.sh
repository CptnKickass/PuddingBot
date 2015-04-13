#!/usr/bin/env bash

echo "PRIVMSG #goose :time.sh loaded" >> "${output}"

if [[ -n "${currDay}" ]]; then
	if [[ "${currDay}" -ne "$(date +%d)" ]]; then
		source ./bin/core/log.sh --day
	fi
else
	currDay="$(date +%d)"
fi

if [[ "${idleTime}" -ne "0" ]]; then
	for chan in var/.last/*; do
		old="$(<${chan})"
		cur="$(date +%s)"
		if [[ "$(( ${cur} - ${old} ))" -ge "${idleTime}" ]]; then
			chan="${chan#var/.last/}"
			readarray -t rand < "${idleLines}"
			rand=(${rand[${RANDOM} % ${#rand[@]} ]] })
			if fgrep -q "\${randomNick}" <<<"${rand[@]}"; then
				senderTarget="${chan}"
				getRandomNick;
			fi
			if [[ "${rand[0],,}" == "say" ]]; then
				echo "PRIVMSG ${chan} :${rand[@]:1}" >> "${output}"
			else
				echo "PRIVMSG ${chan} :${rand}" >> "${output}"
			fi
			echo "$(date +%s)" > "var/.last/${chan,,}"
		fi
	done
fi

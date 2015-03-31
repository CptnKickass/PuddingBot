#!/usr/bin/env bash

if [[ "${isHelp}" -ne "0" ]]; then
	outAct="NOTICE"
	senderTarget="${senderNick}"
elif [[ "${isCtcp}" -ne "0" ]]; then
	outAct="NOTICE"
else
	outAct="PRIVMSG"
fi

if [[ "${#outArr[@]}" -ne "0" ]]; then
	unset sendArr
	for line in "${outArr[@]}"; do
		while IFS= read -rn350 -d '' sendArr[i++]; do :; done <<< "${line}"
	done
	unset outArr
	for line in "${sendArr[@]}"; do
		# This is a cheap way to remove trailing newlines
		line="$(echo "${line}")"

		if [[ "${directOut}" == "1" ]]; then
			senderTarget="${oMsgArr[@]:(-1):1}"
			line="${senderNick} wants you to know: ${line}"
		elif [[ "${directOut}" == "2" ]]; then
			line=("${oMsgArr[@]:(-1):1}: ${line}")
		fi

		if [[ -n "${line}" ]] && ! [[ "${line}" =~ ^" "+$ ]]; then
			echo "${outAct} ${senderTarget} :${line}" >> "${output}"
			sleep 0.25
		fi
	done
fi

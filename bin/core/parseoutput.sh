#!/usr/bin/env bash

if [[ "${isHelp}" -ne "0" ]]; then
	outAct="NOTICE"
	senderTarget="${senderNick}"
elif [[ "${isCtcp}" -ne "0" ]]; then
	outAct="NOTICE"
else
	outAct="PRIVMSG"
fi
if [[ "${msgArr[1]}" == "PRIVMSG" ]]; then
	directOut="0"
	if [[ "${msgArr[@]:(-2):1}" == ">" ]]; then
		if ! egrep -q "^(#|&)" <<<"${msgArr[@]:(-1):1}"; then
			senderTarget="${msgArr[@]:(-1):1}"
			outA="${senderNick} wants you to know: ${outArr[@]}"
			outArr=("${outA}")
		fi
	elif [[ "${msgArr[@]:(-2):1}" == "|" ]]; then
		directOut="2"
		outArr=("${msgArr[@]:(-1):1}: ${outArr}")
	fi
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
		if [[ -n "${line}" ]] && ! [[ "${line}" =~ ^" "+$ ]]; then
			echo "${outAct} ${senderTarget} :${line}" >> "${output}"
			sleep 0.25
		fi
	done
fi

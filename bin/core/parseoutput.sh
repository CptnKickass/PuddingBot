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
	for outLine in "${outArr[@]}"; do
		while IFS= read -rn350 -d '' sendArr[i++]; do :; done <<< "${outLine}"
	done
	unset outLine
	unset outArr
	for outLine in "${sendArr[@]}"; do
		# This is a cheap way to remove trailing newoutLines
		outLine="$(echo "${outLine}")"

		if [[ "${directOut}" == "1" ]]; then
			senderTarget="${oMsgArr[@]:(-1):1}"
			outLine="${senderNick} wants you to know: ${outLine}"
		elif [[ "${directOut}" == "2" ]]; then
			outLine=("${oMsgArr[@]:(-1):1}: ${outLine}")
		fi

		if [[ -n "${outLine}" ]] && ! [[ "${outLine}" =~ ^" "+$ ]]; then
			echo "${outAct} ${senderTarget} :${outLine}" >> "${output}"
			if [[ "${logIn}" -eq "1" ]]; then
				source ./bin/core/log.sh --out
			fi
			sleep 0.25
		fi
	done
fi

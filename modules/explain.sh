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
modForm=("explain")
modFormCase=""
modHelp="Sometimes people need things explained to them. This module assists in that."
modFlag="m"
target="${msgArr[5]}"
explain="${msgArr[@]:7}"
re="I'm"
explain="${explain//you\'re/${re}}"
re="I"
explain="${explain//you/${re}}"
re="you're"
explain="${explain//she\'s/${re}}"
explain="${explain//he\'s/${re}}"
explain="${explain//they\'re/${re}}"
explain="${explain//she is/you are}"
explain="${explain//he is/you are}"
explain="${explain//they are/you are}"
if [[ -z "${target}" ]]; then
	echo "[Explain] This command requires a target"
elif [[ "${target,,}" == "${nick,,}" ]]; then
	echo "[Explain] ${senderNick}: Insufficient permissions. Try again with sudo."
elif [[ "${target,,}" == "sudo" ]]; then
	echo "[Explain] ${senderNick}: Insufficient permissions. Try again without sudo."
elif [[ -z "${explain}" ]]; then
	echo "[Explain] You didn't tell me what to explain"
	echo "[Explain] (Format is: explain to SnoFox that he's a faggot)"
else
	echo "[Explain] ${target}: ${explain}"
fi

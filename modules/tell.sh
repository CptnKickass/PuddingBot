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
modForm=("tell")
modFormCase=""
modHelp="Sometimes people need things told to them. This module assists in that."
modFlag="m"
target="${msgArr[4]}"
# Format should be:
# :N!U@H PRIVMSG ${target} :!explain <to> ${target} <that> ${explain}
explain=(${msgArr[@]:5})
if [[ "${target,,}" == "me" ]]; then
	target="${senderNick}"
fi
n=0
if [[ "${explain[0],,}" == "to" ]]; then
	explainStr="${explain[@]}"
	explainStr="${explainStr#* }"
	explain=(${explainStr})
fi
for x in "${explain[@]}"; do
	re="you're"
	if [[ "${x,,}" == "you" ]]; then
		x="${x//you/I}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "i" ]]; then
		x="${x//I/you}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "i'm" ]]; then
		x="${x//I\'m/${re}}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "she's" ]]; then
		x="${x//she\'s/${re}}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "he's" ]]; then
		x="${x//he\'s/${re}}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "they're" ]]; then
		x="${x//they\'re/${re}}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "him" ]]; then
		x="${x//him/you}"
		explain[${n}]="${x}"
	elif [[ "${x,,}" == "her" ]]; then
		x="${x//her/you}"
		explain[${n}]="${x}"
	fi
	n=$(( ${n} + 1 ))
done
if [[ -z "${target}" ]]; then
	echo "[Tell] This command requires a target"
elif [[ -z "${explain[@]}" ]]; then
	echo "[Tell] You didn't tell me what to say"
	echo "[Tell] (Format is: !tell SnoFox he's a faggot)"
else
	echo "[Tell] ${target}: ${explain[@]}"
fi

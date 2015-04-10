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
modForm=("8" "8ball")
modFormCase=""
modHelp="Checks the Magic 8 Ball for an answer to your question"
modFlag="m"
a=("As I see it, yes" "It is certain" "It is decidedly so" "Most likely" "Outlook good" "Signs point to yes" "One would be wise to think so" "Naturally" "Without a doubt" "Yes" "Yes, definitely" "You may rely on it" "Reply hazy, try again" "Ask again later" "Better not tell you now" "Cannot predict now" "Concentrate and ask again" "You know the answer better than I" "Maybe..." "You're kidding, right?" "Don't count on it" "In your dreams" "My reply is no" "My sources say no" "Outlook not so good" "Very doubtful")
echo "[8 Ball] ${a[${RANDOM} % ${#a[@]} ]] }"

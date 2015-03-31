#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
			exit 1
		else
			echo "ok"
			exit 0
		fi
	else
		echo "ok"
		exit 0
	fi
fi

modHook="Prefix"
modForm=("8" "8ball")
modFormCase=""
modHelp="Checks the Magic 8 Ball for an answer to your question"
modFlag="m"
a=("As I see it, yes" "It is certain" "It is decidedly so" "Most likely" "Outlook good" "Signs point to yes" "One would be wise to think so" "Naturally" "Without a doubt" "Yes" "Yes, definitely" "You may rely on it" "Reply hazy, try again" "Ask again later" "Better not tell you now" "Cannot predict now" "Concentrate and ask again" "You know the answer better than I" "Maybe..." "You're kidding, right?" "Don't count on it" "In your dreams" "My reply is no" "My sources say no" "Outlook not so good" "Very doubtful")
echo "${a[${RANDOM} % ${#a[@]} ]] }"

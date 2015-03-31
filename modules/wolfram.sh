#!/usr/bin/env bash

## Config
# WolframAlpha API Key
apiKey=""

## Source
if [[ -e "var/.conf" ]]; then
	source var/.conf
else
	nick="Null"
fi

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "tr")
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
modForm=("wolf" "wolfram")
modFormCase=""
modHelp="Queries wolfram alpha for your question"
modFlag="m"
# Color character used to start a category: [1;36m
# Color character used to end a category: [0m
if [[ -z "${apiKey}" ]]; then
	echo "A Wolfram Alpha API key is required"
elif [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	unset wolfArr
	wolfQ="${msgArr[@]:4}"
	# properly encode query
	wolfQ="$(sed 's/+/%2B/g' <<<"${wolfQ}" | tr '\ ' '\+')"
	# fetch and parse result
	result=$(curl -s "http://api.wolframalpha.com/v2/query?input=${wolfQ}&appid=${apiKey}&format=plaintext")
	echo "Wolfram Alpha Results:"
	echo -e "${result}" | tr '\n' '\t' | sed -e 's/<plaintext>/\'$'\n<plaintext>/g' | grep -oE "<plaintext>.*</plaintext>|<pod title=.[^\']*" | sed 's!<plaintext>!!g; s!</plaintext>!!g;  s!<pod title=.*!\\\x1b[1;36m&\\\x1b[0m!g; s!<pod title=.!!g; s!\&amp;!\&!' | tr '\t' '\n' | sed  '/^$/d; s/\ \ */\ /g' | while read line; do
		if egrep -q "$(echo -e "\e\[1;36m")" <<<"${line}"; then
			# It's a category
			echo "${wolfArr[@]}"
			unset wolfArr
			line="$(sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" <<<"${line}")"
			echo "${line}"
			sleep 1
		else
			# It's an answer
			wolfArr+=("${line}")
		fi
	done
	echo "${wolfArr[@]}"
	unset wolfArr
fi

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

modHook="Format"
modForm=("what does the fox say")
modFormCase="No"
modHelp="Spits out a line about what the fox says on demand"
modFlag="m"

responseArr=("Ring-ding-ding-ding-dingeringeding!" "Gering-ding-ding-ding-dingeringeding!" "Wa-pa-pa-pa-pa-pa-pow!" "Hatee-hatee-hatee-ho!" "Joff-tchoff-tchoffo-tchoffo-tchoff!" "Tchoff-tchoff-tchoffo-tchoffo-tchoff!" "Jacha-chacha-chacha-chow!" "Chacha-chacha-chacha-chow!" "Fraka-kaka-kaka-kaka-kow!" "A-hee-ahee ha-hee!" "Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!" "Bay-budabud-dum-bam!" "Abay-ba-da bum-bum bay-do!")
foxResponse="${responseArr[${RANDOM} % ${#responseArr[@]} ]] }"
echo "${foxResponse}"

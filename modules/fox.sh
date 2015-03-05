#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "$depFail" -eq "1" ]; then
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

modHook="Format"
modForm=("what does the fox say")
modFormCase="No"
modHelp="Spits out a line about what the fox says on demand"
modFlag="m"

responseArr=("Ring-ding-ding-ding-dingeringeding!" "Gering-ding-ding-ding-dingeringeding!" "Wa-pa-pa-pa-pa-pa-pow!" "Hatee-hatee-hatee-ho!" "Joff-tchoff-tchoffo-tchoffo-tchoff!" "Tchoff-tchoff-tchoffo-tchoffo-tchoff!" "Jacha-chacha-chacha-chow!" "Chacha-chacha-chacha-chow!" "Fraka-kaka-kaka-kaka-kow!" "A-hee-ahee ha-hee!" "Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!" "Bay-budabud-dum-bam!" "Abay-ba-da bum-bum bay-do!")
foxResponse="${responseArr[${RANDOM} % ${#responseArr[@]} ] }"
echo "${foxResponse}"
exit 0

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
modFormCase="Yes"
modHelp="Spits out a line about what the fox says on demand"
modFlag="m"
((foxResponseNum = RANDOM % 12 + 1))
case $foxResponseNum in
	1) foxResponse="Ring-ding-ding-ding-dingeringeding!";;
	2) foxResponse="Gering-ding-ding-ding-dingeringeding!";;
	3) foxResponse="Wa-pa-pa-pa-pa-pa-pow!";;
	4) foxResponse="Hatee-hatee-hatee-ho!";;
	5) foxResponse="Joff-tchoff-tchoffo-tchoffo-tchoff!";;
	6) foxResponse="Tchoff-tchoff-tchoffo-tchoffo-tchoff!";;
	7) foxResponse="Jacha-chacha-chacha-chow!";;
	8) foxResponse="Chacha-chacha-chacha-chow!";;
	9) foxResponse="Fraka-kaka-kaka-kaka-kow!";;
	10) foxResponse="A-hee-ahee ha-hee!";;
	11) foxResponse="Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!";;
	12) foxResponse="Bay-budabud-dum-bam!";;
	13) foxResponse="Abay-ba-da bum-bum bay-do!";;
esac
foxResponseNum="$(( $foxResponseNum + 1 ))"
echo "${foxResponse}"
exit 0

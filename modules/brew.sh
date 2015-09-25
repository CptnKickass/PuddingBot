#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl")
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
modForm=("brew" "brewing")
modFormCase=""
modHelp="Finds out what's brewing in goose's fermentor"
modFlag="m"

data="$(curl -s "https://brewpi.captain-kickass.net/api.php")"
data="${data#\{}"
data="${data%\}}"
state="${data#*State\":}"
state="${state#\"}"
state="${state%%,*}"
state="${state%%\"*}"
case "${state}" in
	0) state="Idle" ;;
	1) state="" ;;
	2) state="" ;;
	3) state="Heating" ;;
	4) state="Cooling" ;;
	5) state="Waiting to cool" ;;
	6) state="Waiting to heat" ;;
	7) state="Waiting for peak" ;;
	8) state="" ;;
	9) state="" ;;
	*) state="" ;;
esac
if [[ -z "${state}" ]]; then
	state="Unknown"
fi
date="${data#*timeStamp\":}"
date="${date#\"}"
date="${date%%,*}"
date="${date%\"}"
date="$(date -d @${date} "+%a, %b %d, %Y @ %H:%M:%S")"
name="${data#*beerName\":}"
name="${name#\"}"
name="${name%%,*}"
name="${name%\"}"
tempType="${data#*tempFormat\":}"
tempType="${tempType#\"}"
tempType="${tempType%%,*}"
tempType="º${tempType%\"}"
beerTemp="${data#*BeerTemp\":}"
beerTemp="${beerTemp#\"}"
beerTemp="${beerTemp%%,*}"
beerTemp="${beerTemp%\"}"
beerSet="${data#*BeerSet\":}"
beerSet="${beerSet#\"}"
beerSet="${beerSet%%,*}"
beerSet="${beerSet%\"}"
beerAnn="${data#*BeerAnn\":}"
beerAnn="${beerAnn#\"}"
beerAnn="${beerAnn%%,*}"
beerAnn="${beerAnn%\"}"
fridgeTemp="${data#*FridgeTemp\":}"
fridgeTemp="${fridgeTemp#\"}"
fridgeTemp="${fridgeTemp%%,*}"
fridgeTemp="${fridgeTemp%\"}"
fridgeSet="${data#*FridgeSet\":}"
fridgeSet="${fridgeSet#\"}"
fridgeSet="${fridgeSet%%,*}"
fridgeSet="${fridgeSet%\"}"
fridgeAnn="${data#*FridgeAnn\":}"
fridgeAnn="${fridgeAnn#\"}"
fridgeAnn="${fridgeAnn%%,*}"
fridgeAnn="${fridgeAnn%\"}"
roomTemp="${data#*RoomTemp\":}"
roomTemp="${roomTemp#\"}"
roomTemp="${roomTemp%%,*}"
roomTemp="${roomTemp%\"}${tempType}"
if [[ "${beerSet,,}" == "null" ]]; then
	beerTemp="${beerTemp}${tempType}"
else
	beerTemp="${beerTemp}${tempType} (Target: ${beerSet}${tempType})"
fi
if ! [[ "${beerAnn,,}" == "null" ]]; then
	beerTemp="${beerTemp} [${beerAnn}]"
fi
if [[ "${fridgeSet,,}" == "null" ]]; then
	fridgeTemp="${fridgeTemp}${tempType}"
else
	fridgeTemp="${fridgeTemp}${tempType} (Target: ${fridgeSet}${tempType})"
fi
if ! [[ "${fridgeAnn,,}" == "null" ]]; then
	fridgeTemp="${fridgeTemp} [${fridgeAnn}]"
fi

echo "Readings taken at ${date} | Currently brewing: ${name} | Status: ${state} | Beer temp: ${beerTemp} | Fridge temp: ${fridgeTemp} | Room temp: ${roomTemp}"
echo "For more info, check out: https://brewpi.captain-kickass.net/"

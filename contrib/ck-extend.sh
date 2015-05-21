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
modForm=(".*(ck|sf)\.(net)")
modFormCase="No"
modHelp="Extends ck.net -> captain-kickass.net and sf.net -> snofox.net"
modFlag="m"

isCk="0"
isCk="$(egrep -c "(http(s?)://)?(ck|sf).net" <<<"${msgArr[@]}")"
if [[ "${isCk}" -ge "1" ]]; then
	egrep -o "(http(s?)://)?(ck|sf).net([[:alnum:]]|[[:punct:]])+?" <<<"${msgArr[@]}" | while read ckUrl; do
		fixedUrl="${ckUrl/*ck.net/https://captain-kickass.net}"
		fixedUrl="${fixedUrl/*sf.net/https://snofox.net}"
		item="${fixedUrl}"
		echo "[Ck-extend] ${item}"
	done
fi

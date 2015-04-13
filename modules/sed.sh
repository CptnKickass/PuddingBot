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
modForm=("^.*PRIVMSG.*:s/.*/.*/(i|g)?$")
modFormCase="No"
modHelp="Provides sed functionality"
modFlag="m"
target="${msgArr[2]}"
sedCom="${msgArr[@]:(3)}"
sedCom="${sedCom#:}"
sedItem="${sedCom#s/}"
sedItem="${sedItem%%/*}"
if [[ -n "${sedItem}" ]]; then
	sedFlag="${sedCom##*/}"
	if [[ "${sedFlag}" == "i" ]]; then
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep -- -i "${sedItem}" | tail -n 1)"
	else
		prevLine="$(fgrep "PRIVMSG ${target}" "${input}" | egrep -v "s/.*/.*/(i|g|ig)?$" | egrep -- "${sedItem}" | tail -n 1)"
	fi
	prevSend="${prevLine%%!*}"
	prevSend="${prevSend#:}"
	line="${prevLine#* :}"
	if [[ -n "${line}" ]]; then
		lineFixed="$(sed -E "${sedCom}" <<<"${line}")"
		if [[ -n "${lineFixed}" ]] && ! [[ "${lineFixed}" == "${line}" ]] && [[ "${#lineFixed}" -le "200" ]]; then
			echo "[FTFY] <${prevSend}> ${lineFixed}"
		elif [[ -n "${lineFixed}" ]] && ! [[ "${lineFixed}" == "${line}" ]] && [[ "${#lineFixed}" -gt "200" ]]; then
			echo "[FTFY] sed response not sent due to result being over 200 characters"
		fi
	fi
fi

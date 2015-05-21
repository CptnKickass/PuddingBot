#!/usr/bin/env bash

dir=("bin/core" "bin/server" "bin/user" "bin/self" "modules" "contrib" "utils")

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("column")
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
modForm=("sloc")
modFormCase=""
modHelp="Counts the source lines of code in Pudding"
modFlag="m"
total="0"
for d in "${dir[@]}"; do
	n="$(egrep -R -v "(^$|^#|^	+#)" "${d}" | wc -l)"
	total="$(( ${n} + ${total} ))"
done
for d in "${dir[@]}"; do
	n="$(egrep -R -v "(^$|^#|^	+#)" "${d}" | wc -l)"
	echo "[SLOC] ${d}: ${n}"
done | column -t
echo "[SLOC] Total SLOC: ${total}"

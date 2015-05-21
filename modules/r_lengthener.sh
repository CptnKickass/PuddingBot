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
modForm=(".*!.*@.* PRIVMSG (#|&).*[:| ]/?r/[[:alnum:]]+")
modFormCase="No"
modHelp="Extends /r/subreddit into a full subreddit link with some information about it"
modFlag="m"

while read sub; do
	pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "https://www.reddit.com/r/${sub}/about.json")"
	if ! fgrep -q "\"error\"" <<<"${pageSrc}"; then
		subName="${pageSrc#*\"display_name\": \"}"
		subName="${subName%%\"*}"
		tagLine="${pageSrc#*\"title\": \"}"
		tagLine="${tagLine%%\"*}"
		subs="${pageSrc#*\"subscribers\": }"
		subs="${subs%%,*}"
		if [[ "${subs}" -gt "999" ]]; then
			subs="$(printf "%'d" ${subs})"
		fi
		active="${pageSrc#*\"accounts_active\": }"
		active="${active%%,*}"
		if [[ "${active}" -gt "999" ]]; then
			active="$(printf "%'d" ${active})"
		fi
		created="${pageSrc#*\"created\": }"
		created="${created%%,*}"
		created="${created%.*}"
		created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
		echo "[r_Lengthener] https://www.reddit.com/r/${subName} | ${tagLine% } | Created ${created} | ${subs} Subscribers | ${active} Users currently viewing"
	fi
done < <(egrep -o "([[:punct:]]| )/?r/[[:alnum:]]+" <<<"${msgArr[@]}" | sed "s/^.*r\///g" | sort -u)

#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("host")
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
modForm=("host" "dns")
modFormCase=""
modHelp="Checks DNS records for a domain"
modFlag="m"
hostToLookup="${msgArr[4]}"
if [[ -z "${hostToLookup}" ]]; then
	echo "This command requires a parameter."
elif [[ "${hostToLookup,,}" == "localhost" ]]; then
	echo "You must think you're real clever, huh?"
elif [[ "${hostToLookup,,}" == "127.0.0.1" ]]; then
	echo "http://en.wikipedia.org/wiki/Localhost"
elif [[ "${hostToLookup,,}" == "::1" ]]; then
	echo "http://www.lifehack.org/articles/productivity/20-productive-ways-to-use-your-free-time.html"
elif ! egrep -q "((([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[0-9+|a-z+|::?])" <<<"${hostToLookup}"; then
	echo "The domain ${hostToLookup} does not appear to be a valid domain"
else
	hostReply="$(host "${hostToLookup}")"
	cname="$(grep "is an alias for" <<<"${hostReply}" | awk '{print $6}' | sed -E "s/\.$//")" 
	rdns="$(grep "domain name pointer" <<<"${hostReply}" | awk '{print $5}' | sed -E "s/\.$//")"
	v4hosts="$(grep "has address" <<<"${hostReply}" | awk '{print $4}' | tr '\n' ' ' && echo "")" 
	v6hosts="$(grep "has IPv6 address" <<<"${hostReply}" | awk '{print $5}' | tr '\n' ' ' && echo "")"
	mailHosts="$(grep "mail is handled by" <<<"${hostReply}" | awk '{print $7}' | tr '\n' ' ' && echo "")"
	echo "${hostToLookup} DNS Report:"
	if [[ -n "${cname}" ]]; then
		echo "${hostToLookup} is a CNAME for ${cname}"
	fi
	if [[ -n "${rdns}" ]]; then
		echo "${hostToLookup} has a reverse DNS of ${rdns}"
	fi
	if [[ -n "${v4hosts}" ]]; then
		echo "IPv4: ${v4hosts}"
	fi
	if [[ -n "${v6hosts}" ]]; then
		echo "IPv6: ${v6hosts}"
	fi
	if [[ -n "${mailHosts}" ]]; then
		echo "Mail: ${mailHosts}"
	fi
fi

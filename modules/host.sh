#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("host")
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

modHook="Prefix"
modForm=("host" "dns")
modFormCase=""
modHelp="Checks DNS records for a domain"
modFlag="m"
hostToLookup="${msgArr[4]}"
if [ -z "$hostToLookup" ]; then
	echo "This command requires a parameter."
elif ! egrep -q "(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}" <<<"${hostToLookup}"; then
	echo "The domain ${hostToLookup} does not appear to be a valid domain"
else
	hostReply="$(host "$hostToLookup")"
	cname="$(grep "is an alias for" <<<"${hostReply}" | awk '{print $6}' | sed -E "s/\.$//")" 
	rdns="$(grep "domain name pointer" <<<"${hostReply}" | awk '{print $5}' | sed -E "s/\.$//")"
	v4hosts="$(grep "has address" <<<"${hostReply}" | awk '{print $4}' | tr '\n' ' ' && echo "")" 
	v6hosts="$(grep "has IPv6 address" <<<"${hostReply}" | awk '{print $5}' | tr '\n' ' ' && echo "")"
	mailHosts="$(grep "mail is handled by" <<<"${hostReply}" | awk '{print $7}' | tr '\n' ' ' && echo "")"
	echo "$hostToLookup DNS Report:"
	if [ -n "$cname" ]; then
		echo "${hostToLookup} is a CNAME for $cname"
	fi
	if [ -n "$rdns" ]; then
		echo "${hostToLookup} has a reverse DNS of $rdns"
	fi
	if [ -n "$v4hosts" ]; then
		echo "IPv4: $v4hosts"
	fi
	if [ -n "$v6hosts" ]; then
		echo "IPv6: $v6hosts"
	fi
	if [ -n "$mailHosts" ]; then
		echo "Mail: $mailHosts"
	fi
fi
exit 0

#!/usr/bin/env bash

## Config
# Config options go here

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
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

# Hook should either be "Prefix" or "Format". Prefix will patch whatever
# the $comPrefix is, i.e. !command. Format will match a message specific
# format, i.e. the sed module.
hook="Prefix"

# This is where the module source should start
msg="$@"
msg="${msg#${0} }"
com="$(echo "$msg" | awk '{print $4}')"
com="${com:2}"
case "$com" in
	host|dns)
	hostToLookup="$(echo "$msg" | awk '{print $5}')"
	if [ -z "$hostToLookup" ]; then
		echo "This command requires a parameter."
	else
		hostReply="$(host "$hostToLookup")"
		cname="$(echo "$hostReply" | grep "is an alias for" | awk '{print $6}' | sed -E "s/\.$//")" 
		rdns="$(echo "$hostReply" | grep "domain name pointer" | awk '{print $5}' | sed -E "s/\.$//")"
		v4hosts="$(echo "$hostReply" | grep "has address" | awk '{print $4}' | tr '\n' ' ' && echo "")" 
		v6hosts="$(echo "$hostReply" | grep "has IPv6 address" | awk '{print $5}' | tr '\n' ' ' && echo "")"
		mailHosts="$(echo "$hostReply" | grep "mail is handled by" | awk '{print $7}' | tr '\n' ' ' && echo "")"
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
	;;
esac
exit 0

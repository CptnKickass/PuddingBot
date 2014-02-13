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
	deps=("whois")
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
	whois)
	if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
		echo "This command requires a parameter"
	else
		domain="$(echo "$msg" | awk '{print $5}')"
		whois="$(whois "${domain}" | egrep -c "^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri")"
		if [ "$whois" -eq "0" ]; then 
			echo "${domain} IS registered (Domain not available)"
		else
			echo "${domain} is NOT registered (Domain available)"
		fi 
	fi
	;;
esac
exit 0

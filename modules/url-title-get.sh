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

# Hook should either be "Prefix" or "Format". Prefix will patch whatever
# the $comPrefix is, i.e. !command. Format will match a message specific
# format, i.e. the sed module.
modHook="Prefix"

# If the $modHook is "Format", what format should the message match to
# catch the script? This should be a regular expression pattern, mathing
# a regular channel PRIVMSG following the colon (It won't match a /ME)
# For example, if you wanted to match:
#  :goose!goose@goose PRIVMSG #GooseDen :s/foo/bar/
# Your $modForm would be:
#  modForm="^s/.+/.+/"
# Leave blank if you don't need this
modForm=""

# If you need your modForm to be case insensitive, and yes. If not, answer
# no. If you don't need this, leave it blank.
modFormCase=""

# A one liner on how to use the module/what it does
modHelp="This module provides examples on how to write other modules"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@
source var/.conf
message="$@"
containsURL="0"
containsURL="$(echo "$message" | egrep -c "http(s?):\/\/[^ \"\(\)\<\>]*")"
if [ "$containsURL" -ge "1" ] && [ ! "$senderNick" == "$nick" ] && [ "$senderIsAdmin" -eq "1" ]; then
	echo "$message" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | while read messageURL; do
		reqFullCurl="0"
		# Zero means the location is true, no redirect to the destination
		urlCurlContentHeader="$(curl -A "$nick" -m 5 -k -s -L -I "$messageURL")"
		httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
		if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "405")" -eq "1" ]; then
			reqFullCurl="1"
			urlCurlContentHeader="$(curl -A "$nick" -m 5 -k -s -L -o /dev/null -D - "$messageURL")"
			httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
		fi
		locationIsTrue="$(echo "$urlCurlContentHeader" | grep -c "Location:")"
		contentType="$(echo "$urlCurlContentHeader" | egrep -i "Content[ |-]Type:" | tail -n 1)"
		if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "200")" -eq "1" ]; then
			if [ "$(echo "$contentType" | fgrep -c "text/html")" -eq "1" ]; then
				pageTitle="$(curl -A "$nick" -m 5 -k -s -L "$messageURL" | awk -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' | sed -e 's/^[ \t]*//')"
				if [ -z "$pageTitle" ]; then
					pageTitle="[Unable to obtain page title]"
				else
					pageTitle="$(echo "$pageTitle" | w3m -dump -T text/html | tr '\n' ' ')"
				fi
			else
				pageSize="$(fgrep -i "Content-Length" <<<"$pageTitle" | tail -n 1 | awk '{print $2}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }')"
				pageTitle="${contentType} (${pageSize})"
			fi
			if [ "$locationIsTrue" -ne "0" ]; then
				if [ "$requireFullCurl" -eq "1" ]; then
					pageDest="$(curl -A "$nick" -m 5 -k -s -L -o /dev/null -D - "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
				else
					pageDest="$(curl -A "$nick" -m 5 -k -s -L -I "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
				fi
			else
				pageDest="$messageURL"
			fi
			if [ -z "$pageDest" ]; then
				pageDest="[Error: Connection timed out]"
			fi
			if [ "$(echo "$pageDest" | egrep -c "^http(s)?://(www\.)?youtube\.com/")" -eq "1" ]; then
				vidId="${pageDest#*v=}"
				vidId="${vidId:0:11}"
				vidInfo="$(curl -A "$nick" -m 5 -k -s -L "http://gdata.youtube.com/feeds/api/videos/${vidId}")"
				vidSecs="$(echo "$vidInfo" | fgrep "yt:duration")"
				vidSecs="${vidSecs#*yt:duration seconds=\'}"
				vidSecs="${vidSecs%%\'*}"
				vidHours=$((vidSecs/60/60%24))
				vidMinutes=$((vidSecs/60%60))
				vidSeconds=$((vidSecs%60))
				if [ "$(echo "$vidSeconds" | egrep -c "^[0-9]$")" -eq "1" ]; then
					vidSeconds="0${vidSeconds}"
				fi
				if [ "$vidHours" -ne "0" ] && [ "$vidMinutes" -ne "0" ]; then
					pageTitle="${pageTitle} [${vidHours}:${vidMinutes}:${vidSeconds}]"
				elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -ne "0" ]; then
					pageTitle="${pageTitle} [${vidMinutes}:${vidSeconds}]"
				elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -eq "0" ]; then
					pageTitle="${pageTitle} [0:${vidSeconds}]"
				fi
			fi
			if [ "$locationIsTrue" -eq "0" ] && [ -n "$pageTitle" ]; then
				echo "PRIVMSG $senderTarget :[URL] $pageTitle" >> $output
			elif [ "$locationIsTrue" -ne "0" ] && [ -n "$pageTitle" ]; then
				echo "PRIVMSG $senderTarget :[URL] $pageTitle - Destination: ${pageDest}" >> $output
			fi
		else
			if [ -n "$httpResponseCode" ]; then
				echo "PRIVMSG $senderTarget :[URL] $httpResponseCode" >> $output
			fi
		fi
	done
fi

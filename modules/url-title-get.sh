#!/usr/bin/env bash

## Config
# None

## Source
if [ -e "var/.conf" ]; then
	source var/.conf
else
	nick="Null"
fi

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m" "tr" "tail")
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
modHook="Format"
modForm=("^:.+!.+@.+ PRIVMSG.*http(s?):\/\/[^ \"\(\)\<\>]*")
modFormCase="No"
modHelp="Gets a URL's <title> and/or some other useful info"
modFlag="m"
message="$@"
echo "$message" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | while read url; do

reqFullCurl="0"
urlCurlContentHeader="$(curl -A "$nick" -m 5 -k -s -L -I "$url")"
httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"$urlCurlContentHeader" | tail -n 1)"
if echo "$httpResponseCode" | awk '{print $2}' | fgrep -q "405"; then
	reqFullCurl="1"
	urlCurlContentHeader="$(curl -A "$nick" -m 5 -k -s -L -o /dev/null -D - "$url")"
	httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
fi
# Zero means the location is true, no redirect to the destination
locationIsTrue="$(grep -c "Location:" <<<"$urlCurlContentHeader")"
contentType="$(egrep -i "Content[ |-]Type:" <<<"$urlCurlContentHeader" | tail -n 1)"
contentType="${contentType%}"
if echo "$httpResponseCode" | awk '{print $2}' | fgrep -q "200"; then
	if echo "$contentType" | fgrep -q "text/html"; then
		pageTitle="$(curl -A "$nick" -m 5 -k -s -L "$url" | awk -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' | sed -e 's/^[ \t]*//' | w3m -dump -T text/html | tr '\n' ' ')"
		if [ -z "$pageTitle" ]; then
			pageTitle="[Unable to obtain page title]"
		fi
	else
		pageSize="$(fgrep -i "Content-Length" <<<"$urlCurlContentHeader" | tail -n 1 | awk '{print $2}' | awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }')"
		pageTitle="${contentType} (${pageSize})"
	fi
	if [ "$locationIsTrue" -ne "0" ]; then
		if [ "$reqFullCurl" -eq "1" ]; then
			pageDest="$(curl -A "$nick" -m 5 -k -s -L -o /dev/null -D - "$url" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		else
			pageDest="$(curl -A "$nick" -m 5 -k -s -L -I "$url" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		fi
	else
		pageDest="$url"
	fi
	if [ -z "$pageDest" ]; then
		pageDest="[Unable to determine URL destination]"
	fi
	if echo "$pageDest" | egrep -i -q "^http(s)?://(www\.)?youtube\.com/watch\?v\="; then
		vidId="${pageDest#*watch?v=}"
		vidId="${vidId:0:11}"
		vidInfo="$(curl -A "$nick" -m 5 -k -s -L "http://gdata.youtube.com/feeds/api/videos/${vidId}")"
		vidSecs="$(echo "$vidInfo" | fgrep "yt:duration")"
		vidSecs="${vidSecs#*yt:duration seconds=\'}"
		vidSecs="${vidSecs%%\'*}"
		vidHours=$((vidSecs/60/60%24))
		vidMinutes=$((vidSecs/60%60))
		vidSeconds=$((vidSecs%60))
		if echo "$vidSeconds" | egrep -q "^[0-9]$"; then
			vidSeconds="0${vidSeconds}"
		fi
		if [ "$vidHours" -ne "0" ] && [ "$vidMinutes" -ne "0" ]; then
			pageTitle="${pageTitle} [${vidHours}:${vidMinutes}:${vidSeconds}]"
		elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -ne "0" ]; then
			pageTitle="${pageTitle} [${vidMinutes}:${vidSeconds}]"
		elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -eq "0" ]; then
			pageTitle="${pageTitle} [0:${vidSeconds}]"
		fi
	elif echo "$pageDest" | egrep -i -q "^http(s)?://(www\.)?newegg\.com/Product/"; then
		pageSrc="$(curl -A "$nick" -m 5 -k -s -L "$pageDest")"
		itemPrice="$(fgrep -m 1 "product_sale_price" <<<"$pageSrc")"
		itemPrice="${itemPrice#*\'}"
		itemPrice="${itemPrice%*\'*}"
		if [ -n "$itemPrice" ]; then
			pageTitle="${pageTitle} [Price: \$${itemPrice}]"
		fi
	elif echo "$pageDest" | egrep -i -q "^http(s)?://(www\.)?amazon\.com/.*/Product/"; then
		echo "URL is Amazon"
		pageSrc="$(curl -A "$nick" -m 5 -k -s -L "$pageDest")"
		itemPrice="$(grep -m 1 -A 1 "Price:" <<<"$pageSrc" | egrep -o "\\\$[[:digit:]]+\.[[:digit:]]+")"
		if [ -n "$itemPrice" ]; then
			pageTitle="${pageTitle} [Price: ${itemPrice}]"
		fi
	fi
	if [ "$locationIsTrue" -eq "0" ] && [ -n "$pageTitle" ]; then
		echo "[URL] $pageTitle"
	elif [ "$locationIsTrue" -ne "0" ] && [ -n "$pageTitle" ]; then
		pageTitle="$pageTitle - Destination: $pageDest"
		echo "[URL] $pageTitle"
	fi
else
	if [ -n "$httpResponseCode" ]; then
		echo "[URL] Code: $httpResponseCode"
	fi
fi
echo ""

done
exit 0

#!/usr/bin/env bash

## Config
# Path to search for file
searchPath="/home/goose/public_html/captain-kickass.net/files"

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("find")
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
modForm=("recent" "reshare")
modFormCase=""
modHelp="Displays the most recently updated file at captain-kickass.net"
modFlag="m"

re='^[0-9]+$'
if ! [[ ${msgArr[4]} =~ $re ]]; then
	n="1"
elif [ -z "${msgArr[4]}" ]; then
	n="1"
elif [ "${msgArr[4]}" -gt "10" ]; then
	echo "Max results allowed to be displayed is 10"
	n="10"
else
	n="${msgArr[4]}"
fi
find ${searchPath} -type f -printf "%T@ %Tc %p\n" | sort -n | tail -n ${n} | awk '{print $8}' | while read out; do
out="https://${out#*public_html/}"
url="${out}"

reqFullCurl="0"
urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -I "$url")"
urlCurlContentHeader="${urlCurlContentHeader///}"
httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"$urlCurlContentHeader" | tail -n 1 | awk '{print $2}')"
if [ "$httpResponseCode" -eq "502" ]; then
	sleep 5
	urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "$url")"
	urlCurlContentHeader="${urlCurlContentHeader///}"
	httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${urlCurlContentHeader}" | tail -n 1 | awk '{print $2}')"
fi
if [ "$httpResponseCode" -ne "200" ]; then
	reqFullCurl="1"
	urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "$url")"
	urlCurlContentHeader="${urlCurlContentHeader///}"
	httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${urlCurlContentHeader}" | tail -n 1 | awk '{print $2}')"
fi
# Zero means the location is true, no redirect to the destination
locationIsTrue="$(grep -c "Location:" <<<"$urlCurlContentHeader")"
contentType="$(egrep -i "Content[ |-]Type:" <<<"$urlCurlContentHeader" | tail -n 1)"
if [ "$httpResponseCode" -eq "200" ]; then
	if fgrep -q "text/html" <<<"${contentType}"; then
		pageTitle="$(curl -A "${nick}" -m 5 -k -s -L "$url" | fgrep -m 1 "<title")"
		pageTitle="${pageTitle%%</title>*}"
		pageTitle="${pageTitle##*>}"
		pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
		if [ -z "$pageTitle" ]; then
			pageTitle="[Unable to obtain page title]"
		fi
	else
		contentMatches="$(fgrep -c "Content-Length" <<<"$urlCurlContentHeader")"
		if [ "$contentMatches" -eq "0" ]; then
			pageTitle="${contentType} (Unable to determine size)"
		elif [ "$contentMatches" -eq "1" ]; then
			contentLength="$(fgrep -i "Content-Length" <<<"$urlCurlContentHeader" | awk '{print $2}')"
			pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"$contentLength")"
			pageTitle="${contentType} (${pageSize})"
		else
			grepNum="1"
			contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"$urlCurlContentHeader" | awk '{print $2}')"
			while [ "$contentLength" -eq "0" ] && [ "$grepNum" -ne "$contentMatches" ]; do
				grepNum="$(( $grepNum + 1 ))"
				contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"$urlCurlContentHeader" | tail -n 1 | awk '{print $2}')"
			done
			if [ "$contentLength" -eq "0" ]; then
				pageTitle="${contentType} (Unable to determine size)"
			else
				pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"$contentLength")"
				pageTitle="${contentType} (${pageSize})"
			fi
		fi
	fi
	if [ "$locationIsTrue" -ne "0" ]; then
		if [ "$reqFullCurl" -eq "1" ]; then
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "$url" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		else
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -I "$url" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		fi
	else
		pageDest="$url"
	fi
	if [ -z "$pageDest" ]; then
		pageDest="[Unable to determine URL destination]"
	fi
	if egrep -i -q "^http(s)?://(www\.)?youtube\.com/watch\?v\=" <<<"${pageDest}"; then
		vidId="${pageDest#*watch?v=}"
		vidId="${vidId:0:11}"
		vidInfo="$(curl -A "${nick}" -m 5 -k -s -L "http://gdata.youtube.com/feeds/api/videos/${vidId}")"
		vidSecs="$(fgrep "yt:duration" <<<"${vidInfo}")"
		vidSecs="${vidSecs#*yt:duration seconds=\'}"
		vidSecs="${vidSecs%%\'*}"
		vidHours=$((vidSecs/60/60%24))
		vidMinutes=$((vidSecs/60%60))
		vidSeconds=$((vidSecs%60))
		if egrep -q "^[0-9]$" <<<"${vidSeconds}"; then
			vidSeconds="0${vidSeconds}"
		fi
		if [ "$vidHours" -gt "0" ] && egrep -q "^[0-9]$" <<<"${vidMinutes}"; then
			vidMinutes="0${vidMinutes}"
		fi
		if [ "$vidHours" -ne "0" ] && [ "$vidMinutes" -ne "0" ]; then
			pageTitle="${pageTitle} [${vidHours}:${vidMinutes}:${vidSeconds}]"
		elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -ne "0" ]; then
			pageTitle="${pageTitle} [${vidMinutes}:${vidSeconds}]"
		elif [ "$vidHours" -eq "0" ] && [ "$vidMinutes" -eq "0" ]; then
			pageTitle="${pageTitle} [0:${vidSeconds}]"
		fi
	elif egrep -i -q "^http(s)?://(www\.)?newegg\.com/Product/" <<<"${pageDest}"; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "$pageDest")"
		itemPrice="$(fgrep -m 1 "product_sale_price" <<<"$pageSrc")"
		itemPrice="${itemPrice#*\'}"
		itemPrice="${itemPrice%*\'*}"
		if [ "$(fgrep -c "Discontinued" <<<"$itemPrice")" -eq "1" ]; then
			pageTitle="${pageTitle} [Item Discontinued]"
		elif [ -n "$itemPrice" ]; then
			pageTitle="${pageTitle} [Price: \$${itemPrice}]"
		fi
	elif egrep -i -q "^http(s)?://(www\.|smile\.)?amazon\.com/(g|d)p/" <<<"${pageDest}"; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		itemAvailable="$(fgrep -ci "Currently unavailable" <<<"${pageSrc}")"
		if [ "${itemAvailable}" -eq "0" ]; then
			itemPrice="$(egrep -o -m 1 "\\\$([0-9]|,)+\.[0-9][0-9]" <<<"${pageSrc}")"
			pageTitle="${pageTitle} [Price: ${itemPrice}]"
		else
			pageTitle="${pageTitle} [Item not currently available]"
		fi
	fi
	if [ "$locationIsTrue" -eq "0" ] && [ -n "$pageTitle" ]; then
		out="${out} | ${pageTitle}"
	elif [ "$locationIsTrue" -ne "0" ] && [ -n "$pageTitle" ]; then
		pageTitle="$pageTitle - Destination: $pageDest"
		out="${out} | ${pageTitle}"
	fi
else
	if [ -n "$httpResponseCode" ]; then
		out="${out} | Returned ${httpRepsonseCode}"
	fi
fi

echo "${out}"
done

exit 0

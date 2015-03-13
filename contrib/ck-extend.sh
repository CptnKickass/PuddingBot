#!/usr/bin/env bash

## Config
# None

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "${depFail}" -eq "1" ]; then
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
modForm=(".*(ck|sf)\.(net)")
modFormCase="No"
modHelp="Extends ck.net -> captain-kickass.net and sf.net -> snofox.net"
modFlag="m"

# This is where the module source should start
# The whole IRC message will be passed to the script using $@
isCk="0"
isCk="$(egrep -c "(http(s?)://)?(ck|sf).net" <<<"${msgArr[@]}")"
if [ "${isCk}" -ge "1" ]; then
	egrep -o "(http(s?)://)?(ck|sf).net([[:alnum:]]|[[:punct:]])+?" <<<"${msgArr[@]}" | while read ckUrl; do
		fixedUrl="${ckUrl/*ck.net/https://captain-kickass.net}"
		fixedUrl="${fixedUrl/*sf.net/https://snofox.net}"
		item="${fixedUrl}"
		url="${item}"
		reqFullCurl="0"
		urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}")"
		urlCurlContentHeader="${urlCurlContentHeader///}"
		httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${url}CurlContentHeader" | tail -n 1 | awk '{print $2}')"
		if [ "${httpResponseCode}" -eq "502" ]; then
			sleep 5
			urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
			urlCurlContentHeader="${urlCurlContentHeader///}"
			httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${urlCurlContentHeader}" | tail -n 1 | awk '{print $2}')"
		fi
		if [ "${httpResponseCode}" -ne "200" ]; then
			reqFullCurl="1"
			urlCurlContentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
			urlCurlContentHeader="${urlCurlContentHeader///}"
			httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${urlCurlContentHeader}" | tail -n 1 | awk '{print $2}')"
		fi
		# Zero means the location is true, no redirect to the destination
		locationIsTrue="$(grep -c "Location:" <<<"${url}CurlContentHeader")"
		contentType="$(egrep -i "Content[ |-]Type:" <<<"${url}CurlContentHeader" | tail -n 1)"
		if [ "${httpResponseCode}" -eq "200" ]; then
			if fgrep -q "text/html" <<<"${contentType}"; then
				pageTitle="$(curl -A "${nick}" -m 5 -k -s -L "${url}" | fgrep -m 1 "<title")"
				pageTitle="${pageTitle%%</title>*}"
				pageTitle="${pageTitle##*>}"
				pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
				if [ -z "${pageTitle}" ]; then
					pageTitle="[Unable to obtain page title]"
				fi
			else
				contentMatches="$(fgrep -c "Content-Length" <<<"${url}CurlContentHeader")"
				if [ "${contentMatches}" -eq "0" ]; then
					pageTitle="${contentType} (Unable to determine size)"
				elif [ "${contentMatches}" -eq "1" ]; then
					contentLength="$(fgrep -i "Content-Length" <<<"${url}CurlContentHeader" | awk '{print $2}')"
					pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
					pageTitle="${contentType} (${pageSize})"
				else
					grepNum="1"
					contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${url}CurlContentHeader" | awk '{print $2}')"
					while [ "${contentLength}" -eq "0" ] && [ "${grepNum}" -ne "${contentMatches}" ]; do
						grepNum="$(( ${grepNum} + 1 ))"
						contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${url}CurlContentHeader" | tail -n 1 | awk '{print $2}')"
					done
					if [ "${contentLength}" -eq "0" ]; then
						pageTitle="${contentType} (Unable to determine size)"
					else
						pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
						pageTitle="${contentType} (${pageSize})"
					fi
				fi
			fi
			if [ "${locationIsTrue}" -ne "0" ]; then
				if [ "${reqFullCurl}" -eq "1" ]; then
					pageDest="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}" | grep "Location:" | tail -n 1 | awk '{print $2}')"
				else
					pageDest="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}" | grep "Location:" | tail -n 1 | awk '{print $2}')"
				fi
			else
				pageDest="${url}"
			fi
			if [ -z "${pageDest}" ]; then
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
				if [ "${vidHours}" -gt "0" ] && egrep -q "^[0-9]$" <<<"${vidMinutes}"; then
					vidMinutes="0${vidMinutes}"
				fi
				if [ "${vidHours}" -ne "0" ] && [ "${vidMinutes}" -ne "0" ]; then
					pageTitle="${pageTitle} [${vidHours}:${vidMinutes}:${vidSeconds}]"
				elif [ "${vidHours}" -eq "0" ] && [ "${vidMinutes}" -ne "0" ]; then
					pageTitle="${pageTitle} [${vidMinutes}:${vidSeconds}]"
				elif [ "${vidHours}" -eq "0" ] && [ "${vidMinutes}" -eq "0" ]; then
					pageTitle="${pageTitle} [0:${vidSeconds}]"
				fi
			elif egrep -i -q "^http(s)?://(www\.)?newegg\.com/Product/" <<<"${pageDest}"; then
				pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${pageDest}")"
				itemPrice="$(fgrep -m 1 "product_sale_price" <<<"${pageSrc}")"
				itemPrice="${itemPrice#*\'}"
				itemPrice="${itemPrice%*\'*}"
				if [ "$(fgrep -c "Discontinued" <<<"${itemPrice}")" -eq "1" ]; then
					pageTitle="${pageTitle} [Item Discontinued]"
				elif [ -n "${itemPrice}" ]; then
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
			if [ "${locationIsTrue}" -eq "0" ] && [ -n "${pageTitle}" ]; then
				item="${item} | ${pageTitle}"
			elif [ "${locationIsTrue}" -ne "0" ] && [ -n "${pageTitle}" ]; then
				pageTitle="${pageTitle} - Destination: ${pageDest}"
				iitem="${item} | ${pageTitle}"
			fi
		else
			if [ -n "${httpResponseCode}" ]; then
				item="${item} | Returned ${httpRepsonseCode}"
			fi
		fi
		echo "[Expanded URL] ${item}"
	done
fi
exit 0

#!/usr/bin/env bash

## Config
# YouTube v3 API
apiKey=""
# None

## Source
if ! [[ -e "var/.conf" ]]; then
	nick="Null"
fi

# Check dependencies 
if [[ "${1}" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m" "tr" "tail")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
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
modForm=("^:.+!.+@.+ PRIVMSG (&|#).* :.*?http(s?):\/\/[^ \"\(\)\<\>]*")
modFormCase="Yes"
modHelp="Gets a URL's <title> and/or some other useful info"
modFlag="m"

if [[ -z "${apiKey}" ]]; then
	echo "A Google API key for YouTube is required"
	exit 255
fi

ytVid () {
	if [[ "${url#*://}" =~ "youtu.be"* ]]; then
		vidId="${url#*youtu.be/}"
		vidId="${vidId:0:11}"
	else
		vidId="${url#*watch?v=}"
		vidId="${vidId:0:11}"
	fi
	apiUrl="https://www.googleapis.com/youtube/v3/videos?id=${vidId}&key=${apiKey}&part=snippet,contentDetails"
	vidInfo="$(curl -A "${nick}" -m 5 -k -s -L "${apiUrl}")"
	vidTitle="$(fgrep -m 1 "\"title\": \"" <<<"${vidInfo}")"
	vidTitle="${vidTitle%\",*}"
	vidTitle="${vidTitle#*\"title\": \"}"
	duration="$(fgrep "\"duration\": \"PT" <<<"${vidInfo}")"
	duration="${duration#*PT}"
	duration="${duration%\",*}"
	duration="${duration,,}"
	pageTitle="[Youtube] ${vidTitle} [${duration}]"
}

getTitle () {
	titleStart="$(fgrep -m 1 -n "<title" <<<"${pageSrc}" | awk '{print $1}')"
	titleStart="${titleStart%%:*}"
	titleEnd="$(fgrep -m 1 -n "</title>" <<<"${pageSrc}" | awk '{print $1}')"
	titleEnd="${titleEnd%%:*}"
	if [[ "${titleStart}" -eq "${titleEnd}" ]]; then
		pageTitle="$(curl -A "${nick}" -m 5 -k -s -L "${url}" | egrep -m 1 "<title.*</title>")"
		pageTitle="${pageTitle%%</title>*}"
		pageTitle="${pageTitle##*>}"
		pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
		if [[ -z "${pageTitle}" ]]; then
			pageTitle="[Unable to obtain page title]"
		fi
	else
		tmp="$(mktemp)"
		tmp2="$(mktemp)"
		echo "${pageSrc}" > "${tmp}"
		head -n ${titleEnd} "${tmp}" | tail -n $(( ${titleStart} + 1 )) > "${tmp2}"
		rm "${tmp}"
		pageTitle="$(tr '\n' ' ' < "${tmp2}")"
		rm "${tmp2}"
		pageTitle="${pageTitle%%</title>*}"
		pageTitle="${pageTitle##*>}"
		pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
		if [[ -z "${pageTitle}" ]]; then
			pageTitle="[Unable to obtain page title]"
		fi
	fi
}

otherSite () {
	reqFullCurl="0"
	contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}")"
	contentHeader="${contentHeader///}"
	httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
	if [[ "${httpResponseCode}" -eq "502" ]]; then
		sleep 3
		contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
		contentHeader="${contentHeader///}"
		httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
		if [[ "${httpResponseCode}" -eq "502" ]]; then
			sleep 3
			contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
			contentHeader="${contentHeader///}"
			httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
			if [[ "${httpResponseCode}" -eq "502" ]]; then
				sleep 3
				contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
				contentHeader="${contentHeader///}"
				httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
			fi
		fi
	fi
	
	if [[ "${httpResponseCode}" -ne "200" ]]; then
		reqFullCurl="1"
		contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
		contentHeader="${contentHeader///}"
		httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
	fi
	
	# Zero means the location is true, no (httpd) redirect to the destination
	locationIsTrue="$(grep -c "Location:" <<<"${contentHeader}")"
	alreadyMatched="0"
	if [[ "${locationIsTrue}" -ne "0" ]]; then
		if [[ "${reqFullCurl}" -eq "1" ]]; then
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		else
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}" | grep "Location:" | tail -n 1 | awk '{print $2}')"
		fi
		url="${pageDest}"
		url="${url///}"
	else
		pageDest="${url}"
	fi

	if egrep -i -q "^http(s)?://((www\.)?youtube\.com/watch\?v\=|youtu.be/)" <<<"${url}"; then
		alreadyMatched="1"
		ytVid;
		if [[ "${httpResponseCode}" -eq "429" ]]; then
			reqFullCurl="0"
			contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${apiUrl}")"
			contentHeader="${contentHeader///}"
			httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
		fi
	elif egrep -i -q "^http(s)?://(www\.)?newegg\.com/Product/" <<<"${url}"; then
		alreadyMatched="1"
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		getTitle;
		itemPrice="$(fgrep -m 1 "product_sale_price" <<<"${pageSrc}")"
		itemPrice="${itemPrice#*\'}"
		itemPrice="${itemPrice%*\'*}"
		if [[ "$(fgrep -c "Discontinued" <<<"${itemPrice}")" -eq "1" ]]; then
			pageTitle="${pageTitle} [Item Discontinued]"
		elif [[ -n "${itemPrice}" ]]; then
			pageTitle="${pageTitle} [Price: \$${itemPrice}]"
		fi
	elif egrep -i -q "^http(s)?://(www\.|smile\.)?amazon\.com/(.*/)?(g|d)p/" <<<"${url}"; then
		alreadyMatched="1"
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		getTitle;
		itemAvailable="$(fgrep -ci "Currently unavailable" <<<"${pageSrc}")"
		if [[ "${itemAvailable}" -eq "0" ]]; then
			itemPrice="$(egrep -o -m 1 "\\\$([0-9]|,)+\.[0-9][0-9]" <<<"${pageSrc}")"
			pageTitle="${pageTitle} [Price: ${itemPrice}]"
		else
			pageTitle="${pageTitle} [Item not currently available]"
		fi
	fi
	
	if [[ "${httpResponseCode}" -eq "200" ]]; then
		contentType="$(egrep -i "Content[ |-]Type:" <<<"${contentHeader}" | tail -n 1)"
		if fgrep -q "text/html" <<<"${contentType}"; then
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
			getTitle;
		elif [[ "${alreadyMatched}" -eq "0" ]]; then
			contentMatches="$(fgrep -c "Content-Length" <<<"${contentHeader}")"
			if [[ "${contentMatches}" -eq "0" ]]; then
				pageTitle="${contentType} (Unable to determine size)"
			elif [[ "${contentMatches}" -eq "1" ]]; then
				contentLength="$(fgrep -i "Content-Length" <<<"${contentHeader}" | awk '{print $2}')"
				pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
				pageTitle="${contentType} (${pageSize})"
			else
				grepNum="1"
				contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${contentHeader}" | awk '{print $2}')"
				while [[ "${contentLength}" -eq "0" ]] && [[ "${grepNum}" -ne "${contentMatches}" ]]; do
					grepNum="$(( ${grepNum} + 1 ))"
					contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
				done
				if [[ "${contentLength}" -eq "0" ]]; then
					pageTitle="${contentType} (Unable to determine size)"
				else
					pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
					pageTitle="${contentType} (${pageSize})"
				fi
			fi
		fi
		if [[ -z "${pageDest}" ]]; then
			pageDest="[Unable to determine URL destination]"
		fi
		if [[ "${locationIsTrue}" -ne "0" ]] && [[ -n "${pageTitle}" ]]; then
			pageTitle="${pageTitle} - Destination: ${pageDest}"
		fi
	else
		if [[ -n "${httpResponseCode}" ]]; then
			pageTitle="Returned ${httpResponseCode}"
		fi
	fi
}

egrep -i -o "http(s?):\/\/[^ \"\(\)\<\>]*" <<<"${msgArr[@]}" | while read url; do
	if egrep -i -q "^http(s)?://((www\.)?youtube\.com/watch\?v\=|youtu.be/)" <<<"${url}"; then
		ytVid;
	elif egrep -i -q "^http(s)?://(www\.)?newegg\.com/Product/" <<<"${url}"; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		getTitle;
		itemPrice="$(fgrep -m 1 "product_sale_price" <<<"${pageSrc}")"
		itemPrice="${itemPrice#*\'}"
		itemPrice="${itemPrice%*\'*}"
		if [[ "$(fgrep -c "Discontinued" <<<"${itemPrice}")" -eq "1" ]]; then
			pageTitle="${pageTitle} [Item Discontinued]"
		elif [[ -n "${itemPrice}" ]]; then
			pageTitle="${pageTitle} [Price: \$${itemPrice}]"
		fi
	elif egrep -i -q "^http(s)?://(www\.|smile\.)?amazon\.com/(.*/)?(g|d)p/" <<<"${url}"; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		getTitle;
		itemAvailable="$(fgrep -ci "Currently unavailable" <<<"${pageSrc}")"
		if [[ "${itemAvailable}" -eq "0" ]]; then
			itemPrice="$(egrep -o -m 1 "\\\$([0-9]|,)+\.[0-9][0-9]" <<<"${pageSrc}")"
			pageTitle="${pageTitle} [Price: ${itemPrice}]"
		else
			pageTitle="${pageTitle} [Item not currently available]"
		fi
	else
		otherSite;
	fi
	echo "[URL] ${pageTitle}"
done

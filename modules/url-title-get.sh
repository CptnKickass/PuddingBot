			containsURL="0"
			containsURL="$(echo "$message" | egrep -c "http(s?):\/\/[^ \"\(\)\<\>]*")"
			if [ "$containsURL" -ge "1" ] && [ ! "$senderNick" == "Pudding" ] && [ "$senderIsAdmin" -eq "1" ]; then
				echo "$message" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" | while read messageURL; do
					unset locationIsTrue
					unset pageTitle
					unset pageDest
					reqFullCurl="0"
					# Zero means the location is true, no redirect to the destination
					urlCurlContentHeader="$(curl -A 'Pudding' -m 5 -k -s -L -I "$messageURL")"
					httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
					if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "405")" -eq "1" ]; then
						reqFullCurl="1"
						urlCurlContentHeader="$(curl -A 'Pudding' -m 5 -k -s -L -o /dev/null -D - "$messageURL")"
						httpResponseCode="$(echo "$urlCurlContentHeader" | egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" | tail -n 1)"
					fi
					locationIsTrue="$(echo "$urlCurlContentHeader" | grep -c "Location:")"
					contentType="$(echo "$urlCurlContentHeader" | egrep -i "Content[ |-]Type:" | tail -n 1)"
					if [ "$(echo "$httpResponseCode" | awk '{print $2}' | fgrep -c "200")" -eq "1" ]; then
						if [ "$(echo "$contentType" | fgrep -c "text/html")" -eq "1" ]; then
							pageTitle="$(curl -A 'Pudding' -m 5 -k -s -L "$messageURL" | awk -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' | sed -e 's/^[ \t]*//')"
							if [ -z "$pageTitle" ]; then
								pageTitle="[Unable to obtain page title]"
							else
								pageTitle="$(echo "$pageTitle" | w3m -dump -T text/html | tr '\n' ' ')"
							fi
						else
							pageTitle="${contentType}"
						fi
						if [ "$locationIsTrue" -ne "0" ]; then
							if [ "$requireFullCurl" -eq "1" ]; then
								pageDest="$(curl -A 'Pudding' -m 5 -k -s -L -o /dev/null -D - "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
							else
								pageDest="$(curl -A 'Pudding' -m 5 -k -s -L -I "$messageURL" | grep "Location:" | tail -n 1 | awk '{print $2}')"
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
							vidInfo="$(curl -A 'Pudding' -m 5 -k -s -L "http://gdata.youtube.com/feeds/api/videos/${vidId}")"
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

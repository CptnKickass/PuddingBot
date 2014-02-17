			isCk="0"
			isCk="$(echo "$message" | egrep -c "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*")"
			if [ "$isCk" -ge "1" ]; then
				echo "$message" | egrep -o "(http(s?):\/\/)?(ck|sf).net[^ \"\(\)\<\>]*" | while read ckUrl; do
					fixedUrl="$(echo "$ckUrl" | sed "s/.*ck\.net/https:\/\/captain-kickass\.net/i" | sed "s/.*sf\.net/http:\/\/snofox\.net/i")"
					echo "PRIVMSG $senderTarget :[URL] $fixedUrl" >> $output
				done
			fi

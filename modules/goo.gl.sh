# goo.gl API key
googleApi=""
shorten)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		shortItem="$(egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*" "${input}" | tail -n 1)"
		echo "PRIVMSG $senderTarget :Shortening most recently spoken URL (${shortItem})" >> $output
	else
		shortItem="$(read -r one two three four rest <<<"$message"; echo "$rest" | egrep -o "http(s?):\/\/[^ \"\(\)\<\>]*")"
	fi
	shortUrl="$(curl -A 'Pudding' -m 5 -k -s -L -H "Content-Type: application/json" -d "{\"longUrl\": \"${shortItem}\"}" "https://www.googleapis.com/urlshortener/v1/url?key=${googleApi}" | fgrep "\"id\"" | egrep -o "http(s)?://goo.gl/[A-Z|a-z|0-9]+")"
	echo "PRIVMSG $senderTarget :Shortened URL: ${shortUrl}" >> $output
	;;

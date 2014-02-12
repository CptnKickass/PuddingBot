google)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		searchTerm="$(read -r one two thee four rest <<<"$message"; echo "$rest")"
		searchResult="$(curl -s --get --data-urlencode "q=${searchTerm}" http://ajax.googleapis.com/ajax/services/search/web?v=1.0 | sed 's/"unescapedUrl":"\([^"]*\).*/\1/;s/.*GwebSearch",//')"
		if [ "$(echo "$searchResult" | fgrep -c "\"responseDetails\": null,")" -eq "1" ]; then
			echo "PRIVMSG $senderTarget :No results found" >> $output
		else
			echo "PRIVMSG $senderTarget :${searchResult}" >> $output
		fi
	fi
	;;

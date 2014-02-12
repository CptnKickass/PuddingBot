find|search)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		searchItem="$(read -r one two three four rest <<<"$message"; echo "$rest")"
		searchPath="/mnt/storage/goose/public_html/captain-kickass.net"
		results="$(find "${searchPath}" -iname "${searchItem}")"
		resultsNum="$(echo "$results" | wc -l)"
		if [  -z "$results" ]; then
			echo "PRIVMSG $senderTarget :No results found" >> $output
		elif [ "$resultsNum" -gt "10" ]; then
			echo "PRIVMSG $senderTarget :More than 10 results returned. Not printing to prevent spamming the channel." >> $output
		else
			echo "$results" | while read line; do
				item="${line#*public_html/}"
				item="https://${item}"
				echo "PRIVMSG $senderTarget :${item}" >> $output
			done
		fi
	fi
	;;

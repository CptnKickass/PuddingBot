isup)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		siteToCheck="$(echo "$message" | awk '{print $5}' | sed "s/http:\/\///")"
		isSiteUp="$(curl -s "http://isup.me/${siteToCheck}" | fgrep -c "It's just you.")"
		# 1 means it's up, 0 means it's down
		if [ "$isSiteUp"-eq "1" ]; then
			echo "PRIVMSG $senderTarget :${siteToCheck} is UP, according to http://isup.me" >> $output
		else
			echo "PRIVMSG $senderTarget :${siteToCheck} is DOWN, according to http://isup.me" >> $output
		fi
	fi
	;;

whois)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		domain="$(echo "$message" | awk '{print $5}')"
		whois="$(whois "${domain}" | egrep -c "^No match|^NOT FOUND|^Not fo|AVAILABLE|^No Data Fou|has not been regi|No entri")"
		if [ "$whois" -eq "0" ]; then 
			echo "PRIVMSG $senderTarget :${domain} IS registered (Domain not available)" >> $output
		else
			echo "PRIVMSG $senderTarget :${domain} is NOT registered (Domain available)" >> $output
		fi 
	fi
	;;

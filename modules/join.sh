join)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	elif [ "$(echo "$message" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
		echo "PRIVMSG $senderTarget :$(echo "$message" | awk '{print $5}') does not appear to be a valid channel"
	else
		echo "JOIN $(echo "$message" | awk '{print $5}')" >> $output
		echo "PRIVMSG $senderTarget :Joined $(echo "$message" | awk '{print $5}')" >> $output
	fi
	;;

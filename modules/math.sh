calc|math)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		equation="$(read -r one two three four rest <<<"$message"; echo "$rest")"
		result="$(echo "scale=3; ${equation}" | bc 2>&1)"
		echo "PRIVMSG $senderTarget :${result}" >> $output
	fi
	;;

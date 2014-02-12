spell)
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	elif [ -n "$(echo "$message" | awk '{print $5}')" ] && [ -n "$(echo "$message" | awk '{print $6}')" ]; then
		echo "PRIVMSG $senderTarget :Too many parameters for command" >> $output
	else
		spellResult="$(echo "$message" | awk '{print $5}' | ispell | head -n 2 | tail -n 1)"
		spellResultParsed="$(read -r one rest <<<"$spellResult"; echo "$rest")"
		echo "PRIVMSG $senderTarget :${spellResultParsed}" >> $output
	fi
	;;

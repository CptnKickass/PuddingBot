uptime)
	timeDiff="$(( $(date +%s) - $startTime ))"
	days=$((timeDiff/60/60/24))
	hours=$((timeDiff/60/60%24))
	minutes=$((timeDiff/60%60))
	seconds=$((timeDiff%60))
	echo "PRIVMSG $senderTarget :Uptime: $days days, ${hours} hours, ${minutes} minutes, ${seconds} seconds" >> $output

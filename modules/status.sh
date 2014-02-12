status)
	echo "PRIVMSG $senderTarget :I am $nick, currently connected to $server (${actualServer:1} on ${networkName}) via port $port. I am hosted on $(uname -n). My PID is $$. My owner is $owner ($ownerEmail)." >> $output

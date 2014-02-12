host|dns)
hostToLookup="$(echo "$message" | awk '{print $5}')"
if [ -z "$hostToLookup" ]; then
	echo "PRIVMSG $senderTarget :This command requires a parameter." >> $output
else
	hostReply="$(host "$hostToLookup")"
	cname="$(echo "$hostReply" | grep "is an alias for" | awk '{print $6}' | sed -E "s/\.$//")" 
	rdns="$(echo "$hostReply" | grep "domain name pointer" | awk '{print $5}' | sed -E "s/\.$//")"
	v4hosts="$(echo "$hostReply" | grep "has address" | awk '{print $4}' | tr '\n' ' ' && echo "")" 
	v6hosts="$(echo "$hostReply" | grep "has IPv6 address" | awk '{print $5}' | tr '\n' ' ' && echo "")"
	mailHosts="$(echo "$hostReply" | grep "mail is handled by" | awk '{print $7}' | tr '\n' ' ' && echo "")"
	echo "PRIVMSG $senderTarget :$hostToLookup DNS Report:" >> $output
	if [ -n "$cname" ]; then
		echo "PRIVMSG $senderTarget :${hostToLookup} is a CNAME for $cname" >> $output
	fi
	if [ -n "$rdns" ]; then
		echo "PRIVMSG $senderTarget :${hostToLookup} has a reverse DNS of $rdns" >> $output
	fi
	if [ -n "$v4hosts" ]; then
		echo "PRIVMSG $senderTarget :IPv4: $v4hosts" >> $output
	fi
	if [ -n "$v6hosts" ]; then
		echo "PRIVMSG $senderTarget :IPv6: $v6hosts" >> $output
	fi
	if [ -n "$mailHosts" ]; then
		echo "PRIVMSG $senderTarget :Mail: $mailHosts" >> $output
	fi
fi

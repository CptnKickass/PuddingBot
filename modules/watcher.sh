#!/usr/bin/env sh

input="${1#*public_html/}"
if [ "$(echo "$input" | egrep -c "(\.sw(p|x|px)$)")" -eq "1" ]; then
	exit 0
fi

input="https://${input}"

if [ -e /home/goose/bashbot-data/outbound.txt ]; then
	echo "PRIVMSG #foxden :[WEB] File Created: $input" >> /home/goose/bashbot-data/outbound.txt
fi

exit 0

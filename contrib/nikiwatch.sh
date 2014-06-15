#!/usr/bin/env sh
if [ -e /home/goose/PuddingBot/var/outbound ]; then
	echo "PRIVMSG #goose :[WATCHER] ${1} has been updated with new data" >> /home/goose/PuddingBot/var/outbound
fi
exit 0

#!/usr/bin/env bash

case "${msgArr[1]^^}" in
	MODE)
	;;
	JOIN)
	;;
	PART)
	;;
	*)
	echo "$(date -R) [${0}] ${msgArr[@]}" >> "${dataDir}/$(<var/bot.pid).debug"
	;;
esac

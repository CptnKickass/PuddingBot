#!/usr/bin/env bash

#########################################################################
#                                                                       #
# Copyright (C) 2014 goose <goose@captain-kickass.net>                  #
# This work is free. You can redistribute it and/or modify it under the #
# terms of the Do What The Fuck You Want To Public License, Version 2,  #
# as published by Sam Hocevar.                                          #
#                                                                       #
#             DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE               #
#                     Version 2, December 2004                          #
#                                                                       #
#  Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>                     #
#                                                                       #
#  Everyone is permitted to copy and distribute verbatim or modified    #
#  copies of this license document, and changing it is allowed as long  #
#  as the name is changed.                                              #
#                                                                       #
#             DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE               #
#    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION    #
#                                                                       #
#   0. You just DO WHAT THE FUCK YOU WANT TO.                           #
#                                                                       #
# /* This program is free software. It comes without any warranty, to   #
#  * the extent permitted by applicable law. You can redistribute it    #
#  * and/or modify it under the terms of the Do What The Fuck You Want  #
#  * To Public License, Version 2, as published by Sam Hocevar. See     #
#  * http://www.wtfpl.net/ for more details. */                         #
#                                                                       #
#########################################################################

## Version 1.0.0

## Source

# Define some variables.
ver="$(fgrep -m 1 "## Version" "${0}" | awk '{print $3}')"
red='\E[0;31m'
green='\E[0;32m'
yellow='\E[1;33m'
reset="\033[1m\033[0m"

# Check for args for non interactive mode. If not present, start in interactive mode.
if [ -n "${1}" ]; then
	# Convert ${1} to lowercase
	arg="${1,,}"
	case "${arg}" in
		--start)
		;;
		--stop)
		;;
		--restart)
		;;
		--status)
		;;
		--force-start)
		;;
		--force-stop)
		;;
		--version)
			echo "Version: ${ver}"
		;;
		--help)
			echo "Available commands: --start --stop --restart --status --force-start --force-stop --version"
		;;
		*)
			echo "Invalid option! Available commands:"
			echo "--start --stop --restart --status --force-start --force-stop --version"
			exit 1
		;;
	esac
exit 0
fi

# If we bypassed the above if statement, we must be starting in interactive mode.
clear
while true; do
	echo "PuddingBot Interactive Console"
	if [ -e "var/bot.pid" ]; then
		# PID exists. Is it actually running?
		pid="$(< var/bot.pid)"
		if [ "$(ps aux | awk '{print $2}' | fgrep -c "${pid}")" -eq "1" ]; then
			# The bot's PID matches an actual process
			echo -e "Bot status: ${green}Running${reset}"
		else
			echo -e "Bot status: ${yellow}Unknown${reset}"
		fi
	else
		echo -e "Bot status: ${red}Not running${reset}"
	fi
	echo ""
	echo "Please choose an option:"
	echo ""
	echo "[0] Exit console"
	echo ""
	echo "[1] Start bot"
	echo "[2] Stop bot"
	echo "[3] Restart bot"
	echo ""
	echo "[4] Check bot status"
	echo ""
	echo "[5] Force start bot"
	echo "[6] Force stop bot"
	echo ""
	echo "[7] Print bot version"
	echo ""
	echo "Please choose a number:"
	read -p "> " opt
	echo ""
	case "$opt" in
		0)
			echo "Goodbye."
			exit 0
		;;
		1)
		;;
		2)
		;;
		3)
		;;
		4)
		;;
		5)
		;;
		6)
		;;
		7)
			echo "Version: ${ver}"
		;;
		8)
		;;
		*)
			echo "Invalid option!"
		;;
	esac
	echo ""
	read -p "[Press any key to continue]" null
	clear
done

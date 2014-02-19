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
badConf="0"

# Check dependencies for the controller script
deps=("read" "fgrep" "egrep" "echo" "cut" "sed" "ps" "awk")
for i in ${deps[@]}; do
	if ! command -v ${i} > /dev/null 2>&1; then
		echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
		exit 1 
	fi
done

# Define some functions
checkSanity () {
	if [ -e "var/.conf" ]; then
		rm -f "var/.conf"
	fi
	botNick="$(egrep -m 1 "^nick=" "pudding.conf")"
	tmpBotNick="${botNick#*\"}"
	tmpBotNick="${tmpBotNick%\"}"
	if [ -z "$tmpBotNick" ]; then
		echo -e "Config option ${red}nick${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botNick}" >> var/.conf
	fi
	botIdent="$(egrep -m 1 "^ident=" "pudding.conf")"
	tmpBotIdent="${botIdent#*\"}"
	tmpBotIdent="${tmpBotIdent%\"}"
	if [ -z "$tmpBotIdent" ]; then
		echo -e "Config option ${red}ident${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botIdent}" >> var/.conf
	fi
	botGecos="$(egrep -m 1 "^gecos=" "pudding.conf")"
	tmpBotGecos="${botGecos#*\"}"
	tmpBotGecos="${tmpBotGecos%\"}"
	if [ -z "$tmpBotGecos" ]; then
		echo -e "Config option ${red}gecos${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botGecos}" >> var/.conf
	fi
	egrep -m 1 "^channels=" "pudding.conf" >> var/.conf
	botServer="$(egrep -m 1 "^server=" "pudding.conf")"
	tmpBotServer="${botServer#*\"}"
	tmpBotServer="${tmpBotServer%\"}"
	if [ -z "$tmpBotServer" ]; then
		echo -e "Config option ${red}server${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botServer}" >> var/.conf
	fi
	botPort="$(egrep -m 1 "^port=" "pudding.conf")"
	tmpBotPort="${botPort#*\"}"
	tmpBotPort="${tmpBotPort%\"}"
	if [ -z "$tmpBotPort" ]; then
		echo -e "Config option ${red}port${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botPort}" >> var/.conf
	fi
	botOwner="$(egrep -m 1 "^owner=" "pudding.conf")"
	tmpBotOwner="${botOwner#*\"}"
	tmpBotOwner="${tmpBotOwner%\"}"
	if [ -z "$tmpBotOwner" ]; then
		echo -e "Config option ${red}owner${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botOwner}" >> var/.conf
	fi
	botOwnerEmail="$(egrep -m 1 "^ownerEmail=" "pudding.conf")"
	tmpBotOwnerEmail="${botOwnerEmail#*\"}"
	tmpBotOwnerEmail="${tmpBotOwnerEmail%\"}"
	if [ -z "$tmpBotOwnerEmail" ]; then
		echo -e "Config option ${red}ownerEmail${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botOwnerEmail}" >> var/.conf
	fi
	botPrefix="$(egrep -m 1 "^comPrefix=" "pudding.conf")"
	tmpBotPrefix="${botPrefix#*\"}"
	tmpBotPrefix="${tmpBotPrefix%\"}"
	if [ -z "$tmpBotPrefix" ]; then
		echo -e "Config option ${red}comPrefix${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botPrefix}" >> var/.conf
	fi
	botLog="$(egrep -m 1 "^logIn=" "pudding.conf")"
	tmpBotLog="${botLog#*\"}"
	tmpBotLog="${tmpBotLog%\"}"
	tmpBotLog="$(echo "$tmpBotLog" | cut -b 1 | sed "s/y/1/i" | sed "s/n/0/i")"
	if [ "$tmpBotLog" -ne "0" ] && [ "$tmpBotLog" -ne "1" ]; then
		echo -e "Config option ${red}logIn${reset} appears to be invalid!"
		badConf="1"
	else
		echo "logIn=\"${tmpBotLog}\"" >> var/.conf
	fi
	botData="$(egrep -m 1 "^dataDir=" "pudding.conf")"
	tmpBotData="${botData#*\"}"
	tmpBotData="${tmpBotData%\"}"
	tmpBotData="${tmpBotData%/}"
	if [ -z "$tmpBotData" ]; then
		echo -e "Config option ${red}dataDir${reset} appears to be invalid!"
		badConf="1"
	else
		echo "dataDir=\"${tmpBotData}\"" >> var/.conf
	fi
	botOutput="$(egrep -m 1 "^output=" "pudding.conf")"
	tmpBotOutput="${botOutput#*\"}"
	tmpBotOutput="${tmpBotOutput%\"}"
	if [ -z "$tmpBotOutput" ]; then
		echo -e "Config option ${red}output${reset} appears to be invalid!"
		badConf="1"
	else
		echo "${botOutput}" >> var/.conf
	fi
}

startBot () {
if [ -e "var/bot.pid" ]; then
	echo "Bot appears to be running already (Under PID: $(<var/bot.pid))"
	return 1
else
	echo "Initiating PuddingBot v${ver}"
	echo ""
	# Check for a sane environment from our variables
	echo "Checking config for sanity"
	checkSanity;

	if [ "$badConf" -eq "1" ]; then
		echo "Please fix above config options prior to start bot."
		return 1
	else
		# Load variables into controller
		echo "Loading variables into controller"
		source ./var/.conf

		# If $dataDir does not exist, create it
		if [ ! -d "$dataDir" ]; then
			echo "Creating data directory"
			mkdir "$dataDir"
		fi

		# If output pipe still exists from last time, remove it
		if [ -e "$output" ]; then
			echo "Removing old pipe (Improper shutdown?)"
			rm -f "$output"
		fi

		# If logging is enabled
		if [ "$logIn" -eq "1" ]; then
			echo "Logging enabled"
			# If logging directory does not exist, create it
			if [ ! -d "${dataDir}/logs" ]; then
				echo "Created log directory"
				mkdir "${dataDir}/logs"
			fi
		fi

		# Check for sanity with the modules
		echo "Checking for modules"
		egrep "^loadMod" "pudding.conf" | sort -u | while read mod; do
			mod="${mod%\"}"
			mod="${mod#*\"}"
			if [ ! -e "modules/${mod}" ]; then
				# No such file exists
				echo -e "Skipped module: ${red}${mod}${reset} (No such module found)"
			else
				# File exists. Check that its dependencies are met.
				./modules/${mod} --dep-check 2>&1 | head -n 1 | while read line; do
					if [[ "$line" == "ok" ]]; then
						echo "${mod}" >> var/.mods
						echo -e "Loaded module:  ${green}${mod}${reset}"
					else
						echo -e "Skipped module: ${red}${mod}${reset} (Dependency check failed)"
					fi
				done
			fi
		done
		# Start the actual bot
		echo "Starting bot"
		./core/core.sh
	fi
fi
}

stopBot () {
if [ -e "var/bot.pid" ]; then
	echo "Sending QUIT to IRCd"
	echo "QUIT :Killed from console" >> $output
	echo "Killing bot PID ($(< var/bot.pid))"
	kill < var/bot.pid
else
	echo "Unable to find bot.pid! (Is the bot even running?)"
fi
}

forceStopBot () {
if [ -e "var/bot.pid" ]; then
	echo "Sending QUIT to IRCd"
	echo "QUIT :Killed from console" >> $output
	echo "Attempting to kill bot PID ($(< var/bot.pid)) nicely"
	kill < var/bot.pid
	if [ -e "var/bot.pid" ]; then
		echo "Quit unsuccessful. Killing bot by all means possible (SIGKILL)"
		kill -9 < var/bot.pid
	fi
	if [ -e "$output" ]; then
		echo "Removing pipe"
		rm -f "$output"
	fi
	if [ -e "var/.conf" ]; then
		rm -f "var/.conf"
	fi
	if [ -e "var/.mods" ]; then
		rm -f "var/.mods"
	fi
else
	echo "Unable to find bot.pid! (Is the bot even running?)"
fi
}

# Check for args for non interactive mode. If not present, start in interactive mode.
if [ -n "${1}" ]; then
	# Convert ${1} to lowercase
	arg="${1,,}"
	case "${arg}" in
		--start)
			startBot;
		;;
		--stop)
			stopBot;
		;;
		--restart)
			stopBot;
			startBot;
		;;
		--status)
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
				echo -e "Bot status: ${red}Stopped${reset}"
			fi
		;;
		--force-stop)
			forceStopBot;
		;;
		--version)
			echo "Version: ${ver}"
		;;
		--help)
			echo "Available commands: --start --stop --restart --status --force-stop --version"
		;;
		*)
			echo "Invalid option! Available commands:"
			echo "--start --stop --restart --status --force-stop --version"
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
	echo "[5] Force stop bot"
	echo ""
	echo "[6] Print bot version"
	echo ""
	echo "[7] Send PRIVMSG as bot"
	echo "[8] Send ACTION as bot"
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
			startBot;
		;;
		2)
			stopBot;
		;;
		3)
			stopBot;
			startBot;
		;;
		4)
		;;
		5)
			forceStopBot;
		;;
		6)
			echo "Version: ${ver}"
		;;
		7)
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

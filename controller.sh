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

## Version 1.0.1

## Source

# Define some variables.
ver="$(fgrep -m 1 "## Version" "${0}" | awk '{print $3}')"
red='\E[0;31m'
green='\E[0;32m'
yellow='\E[1;33m'
reset="\033[1m\033[0m"
badConf="0"
confFile="pudding.conf"

# Check dependencies for the controller script
# Define some functions
checkSanity () {
	deps=("bash" "read" "fgrep" "egrep" "echo" "cut" "sed" "ps" "awk" "nc" "touch" "mktemp")
	for i in ${deps[@]}; do
		echo -n "Checking for dependency ${i}..."
		if ! command -v ${i} > /dev/null 2>&1; then
			echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
			exit 1 
		else
			echo "Found."
		fi
	done
	echo ""
	echo "-----"
	echo ""

	if ! [ -d "var" ]; then
		mkdir var
	fi

	if [ -e "var/.conf" ]; then
		rm -f "var/.conf"
	fi

	# Check to make sure at least one admin exists
	if [ -d "users" ]; then
		echo "Users exist. Checking for presence of administrator..."
		if find users -depth -type f -iname "*.conf" > /dev/null 2>&1; then
			if egrep -q "^flags=\".*A.*\"$" users/*.conf; then
				echo "Administrator exists."
			else
				while ! egrep -q "^flags=\".*A.*\"$" users/*.conf; do
					echo "No admins exist. Please create an administrator before launching bot for the first time."
					./utils/createuser.sh
				done
			fi
		else
			echo "No admins exist. Please create an administrator before launching bot for the first time."
			./utils/createuser.sh
			while ! egrep -q "^flags=\".*A.*\"$" users/*.conf; do
				echo "No admins exist. Please create an administrator before launching bot for the first time."
				./utils/createuser.sh
			done
		fi
	else
		echo "Creating Users Directory..."
		mkdir users
		echo "No admins exist. Please create an administrator before launching bot for the first time."
		./utils/createuser.sh
		while ! egrep -q "^flags=\".*A.*\"$" users/*.conf; do
			echo "No admins exist. Please create an administrator before launching bot for the first time."
			./utils/createuser.sh
		done
	fi

	confReq=("nick" "ident" "gecos" "server" "port" "owner" "ownerEmail" "comPrefix" "genFlags" "logIn" "dataDir" "output" "input")
	for i in "${confReq[@]}"; do
		testVar="$(egrep -m 1 "^${i}=\"" "${confFile}")"
		testVar="${testVar#${i}=\"}"
		testVar="${testVar%\"}"
		if [ -z "${testVar}" ]; then
			echo -e "Config option ${red}${i}${reset} appears to be invalid!"
			badConf="1"
		fi
	done

	sqlUser="$(egrep -m 1 "^sqlUser=\"" "${confFile}")"
	sqlUser="${sqlUser#sqlUser=\"}"
	sqlUser="${sqlUser%\"}"
	if [ -z "${sqlUser}" ]; then
		echo "No SQL Username defined. Disabling SQL support..."
		sqlSupport="0"
	else
		sqlPass="$(egrep -m 1 "^sqlPass=\"" "${confFile}")"
		sqlPass="${sqlPass#sqlPass=\"}"
		sqlPass="${sqlPass%\"}"
		if [ -z "${sqlPass}" ]; then
			echo "No SQL Password defined. Disabling SQL support..."
			sqlSupport="0"
		else
			sqlDB="$(egrep -m 1 "^sqlDBname=\"" "${confFile}")"
			sqlDB="${sqlDB#sqlDBname=\"}"
			sqlDB="${sqlDB%\"}"
			if [ -z "${sqlDB}" ]; then
				echo "No SQL Database name defined. Disabling SQL support..."
				sqlSupport="0"
			else
				mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDB};" > /dev/null 2>&1
				if [ "${?}" -eq "0" ]; then
					echo "Valid SQL username, password, and database name found. Enabling SQL support."
					sqlSupport="1"
				else
					echo "Invalid SQL username, password, and database name entered (Access test failed). Disabling SQL support."
					sqlSupport="0"
				fi
			fi
		fi
	fi

	egrep -v "^#" "${confFile}" | egrep -v "^loadMod=\"" | while read i; do
		testVar="${i}"
		testVar="${testVar#*=\"}"
		testVar="${testVar%\"}"
		if [[ "${i%%=\"*}" == "logIn" ]]; then
			case "${testVar,,}" in
				yes)
				i="logIn=\"1\"";;
				no)
				i="logIn=\"0\"";;
			esac
		fi
		echo "${i}" >> var/.conf
	done
}

startBot () {
if [ -e "var/bot.pid" ]; then
	echo "Bot appears to be running already (Under PID: $(<var/bot.pid))"
	return 1
else
	echo "Initiating PuddingBot v${ver}"
	echo ""
	if [ ! -e "${confFile}" ]; then
		echo "You do not appear to have a \"${confFile}\" file!"
		echo "Did you not copy your EXAMPLE file?"
		exit 255
	fi
	# If output datafile still exists from last time, remove it
	if [ -e "$output" ]; then
		echo "Removing old datafiles (Improper shutdown?)"
		rm -f "$output"
		if [ -e "var/.admins" ]; then
			rm "var/.admins"
		fi
		if [ -d "var/.mods" ]; then
			rm -rf "var/.mods"
		fi
		if [ -e "var/.conf" ]; then
			rm "var/.conf"
		fi
		if [ -e "var/.status" ]; then
			rm "var/.status"
		fi
	fi

	# Check for a sane environment from our variables
	echo "Checking config for sanity"
	checkSanity;

	if [ "$badConf" -eq "1" ]; then
		echo "Please fix above config options prior to start bot."
		exit 255
	else
		# Load variables into controller
		echo "Loading variables into controller"
		source ./var/.conf

		# If $dataDir does not exist, create it
		if [ ! -d "$dataDir" ]; then
			echo "Creating data directory"
			mkdir "$dataDir"
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
		mkdir var/.mods
		egrep "^loadMod" "${confFile}" | sort -u | while read mod; do
			mod="${mod%\"}"
			mod="${mod#*\"}"
			if [ -e "modules/${mod}" ]; then
				# File exists. Check that its dependencies are met.
				./modules/${mod} --dep-check 2>&1 | head -n 1 | while read line; do
					if [[ "$line" == "ok" ]]; then
						cp "modules/${mod}" "var/.mods/${mod}"
						echo -e "Loaded module:  ${green}${mod}${reset}"
					else
						echo -e "Skipped module: ${red}${mod}${reset} (Dependency check failed)"
					fi
				done
			elif [ -e "contrib/${mod}" ]; then
				# File exists. Check that its dependencies are met.
				./contrib/${mod} --dep-check 2>&1 | head -n 1 | while read line; do
					if [[ "$line" == "ok" ]]; then
						cp "contrib/${mod}" "var/.mods/${mod}"
						echo -e "Loaded module:  ${green}${mod}${reset}"
					else
						echo -e "Skipped module: ${red}${mod}${reset} (Dependency check failed)"
					fi
				done
			else
				# No such file exists
				echo -e "Skipped module: ${red}${mod}${reset} (No such module found)"
			fi
		done
		# Start the actual bot
		echo "Starting bot"
		#screen -d -m -S pudding ./core/core.sh
		./bin/core/core.sh > /dev/null 2>&1 &
		#./bin/core/core.sh
	fi
fi
}

startBotDebug () {
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

		# If output datafile still exists from last time, remove it
		if [ -e "$output" ]; then
			echo "Removing old datafile (Improper shutdown?)"
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
		mkdir var/.mods
		egrep "^loadMod" "${confFile}" | sort -u | while read mod; do
			mod="${mod%\"}"
			mod="${mod#*\"}"
			if [ ! -e "modules/${mod}" ]; then
				# No such file exists
				echo -e "Skipped module: ${red}${mod}${reset} (No such module found)"
			else
				# File exists. Check that its dependencies are met.
				./modules/${mod} --dep-check 2>&1 | head -n 1 | while read line; do
					if [[ "$line" == "ok" ]]; then
						cp "modules/${mod}" "var/.mods/${mod}"
						echo -e "Loaded module:  ${green}${mod}${reset}"
					else
						echo -e "Skipped module: ${red}${mod}${reset} (Dependency check failed)"
					fi
				done
			fi
		done
		# Start the actual bot
		echo "Starting bot"
		./bin/core/core.sh
	fi
fi
}

stopBot () {
source var/.conf
if [ -e "var/bot.pid" ]; then
	echo "Sending QUIT to IRCd"
	echo "QUIT :Killed from console" >> $output
	echo "Killing bot PID ($(< var/bot.pid))"
	kill $(<var/bot.pid)
	echo "NOTICE! Due to a known bug of unknown origin, the \"tail -f\" PID cannot be killed by this controller. Please kill it manually."
else
	echo "Unable to find bot.pid! (Is the bot even running?)"
fi
}

forceStopBot () {
source var/.conf
if [ -e "var/bot.pid" ]; then
	echo "Sending QUIT to IRCd"
	echo "QUIT :Killed from console" >> $output
	echo "Attempting to kill bot PID ($(< var/bot.pid)) nicely"
	kill < var/bot.pid
	if [ -e "var/bot.pid" ]; then
		echo "Quit unsuccessful. Killing bot by all means possible (SIGKILL)"
		kill -9 $(<var/bot.pid)
	fi
	if [ -e "$output" ]; then
		echo "Removing datafile"
		rm -f "$output"
	fi
	if [ -e "var/.conf" ]; then
		rm -f "var/.conf"
	fi
	if [ -e "var/.mods" ]; then
		rm -f "var/.mods"
	fi
	if [ -e "var/.status" ]; then
		rm -f "var/.status"
	fi
	if [ -e "var/.admins" ]; then
		rm -f "var/.admins"
	fi
	echo "NOTICE! Due to a known bug of unknown origin, the \"tail -f\" PID cannot be killed by this controller. Please kill it manually."
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
		--debug)
			startBotDebug;
		;;
		--stop)
			stopBot;
		;;
		--restart)
			stopBot;
			sleep 1
			startBot;
		;;
		--from-irc-restart)
			sleep 1
			numTries="0"
			while [ "$numTries" -lt "10" ]; do
				if [ -e "var/bot.pid" ]; then
					numTries="$(( $numTries + 1 ))"
				else
					startBot;
					exit 0
				fi
				sleep 1
			done
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

#!/usr/bin/env bash

unset helpTopic
helpTopic=("(register)" "(set)" "(login)" "(logout)" "(flogout)" "(admins)" "(join)" "(part)" "(speak|say)" "(action|do)" "(nick)" "(ignore)" "(status)" "(die|quit|exit)" "(restart)" "(uptime)")
for i in var/.mods/*.sh; do
	if fgrep -i -q "modHook=\"Prefix\"" "${i}"; then
		file="$(fgrep "modForm=" "${i}")"
		file="${file#*(}"
		file="${file%)}"
		file="${file//\" \"/|}"
		file="${file//\"/}"
	else
		file="${i##*/}"
		file="${file%.sh}"
	fi
	helpTopic+=("(${file})")
done
arg1="${msgArr[4]}"
if [[ -z "${arg1,,}" ]]; then
	echo "Available Help Topics: ${helpTopic[@]}"
elif fgrep -q "${arg1,,}" <<<"${helpTopic[@]}"; then
	case "${arg1,,}" in
		login)
			echo "(${arg1,,}) => Logs you in to the bot"
			;;
		logout)
			echo "(${arg1,,}) => Logs you out of the bot"
			;;
		flogout)
			echo "(${arg1,,}) => Force logs another user out of the bot"
			;;
		admins)
			echo "(${arg1,,}) => Lists the currently logged in admins"
			;;
		join)
			echo "(${arg1,,}) => I'll join a channel"
			;;
		part)
			echo "(${arg1,,}) => I'll part a channel"
			;;
		speak|say)
			echo "(${arg1,,}) => I'll speak a message in a channel"
			;;
		action|do)
			echo "(${arg1,,}) => I'll do a /ME in a channel"
			;;
		nick)
			echo "(${arg1,,}) => I'll change nicks"
			;;
		ignore)
			echo "(${arg1,,}) => I'll ignore a regular expression n!u@h mask"
			;;
		status)
			echo "(${arg1,,}) => I'll give a status report"
			;;
		die|quit|exit)
			echo "(${arg1,,}) => I'll quit IRC and shut down"
			;;
		restart)
			echo "(${arg1,,}) => I'll restart, quitting IRC and joining a new spawn"
			;;
		uptime)
			echo "(${arg1,,}) => I'll give you an uptime report"
			;;
		register)
			echo "(${arg1,,}) => Registers a user into the bot. Format is: \"REGISTER username password\". ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
			;;
		set)
			arg2="${msgArr[5]}"
			case "${arg2,,}" in
				password)
					echo "(${arg1,,})->(${arg2,,}) => Allows you to change your password. Format is: \"SET PASSWORD newpassword\". ***Note that this bot is in debug mode. Although your password will be stored as a sha256 hash in the user files, the raw input/output is being logged for debug purposes. Do not use a password you use anywher else!***"
					;;
				clones)
					echo "(${arg1,,})->(${arg2,,}) => Allows you to set the number of clones you want to allow to simultaneously be logged into your account. Format is: \"SET CLONES n\", where \"n\" is the number of clones you desire."
					;;
				allowedhost)
					arg3="${msgArr[6]}"
					case "${arg3,,}" in
						list)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Lists any known white-listed IDENT@HOST masks on your account, which are authorized to be identified simply by their IDENT@HOST masks using the \"!login\" command."
							;;
						add)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Adds an IDENT@HOST mask to your account's white list, allowing anyone with that IDENT@HOST command to be identified to your account simply by using the \"!login\" command. Note that wild cards are not accepted, the match must be a full IDENT@HOST mask. Format is: \"SET ALLOWEDHOST ADD ident@host\""
							;;
						del|delete|remove)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Remove a whitelisted IDENT@HOST mask from your account, preventing it from being identified to your account simply by using the \"!login\" command. Format is: \"SET ALLOWEDHOST DEL ident@host\""
							;;
						*)
							echo "(${arg1,,})->(${arg2,,}) => Allows you to handle the pre-authenticated IDENT@HOST masks which can be used to identify an account. This means that rather than identifying with a password, you have a white listed IDENT@HOST which can use the \"!login\" command to be identified. Note that wild cards are not accepted, the match must be a full IDENT@HOST mask. Sub-commands are: List, Add, Del, Delete, Remove"
							;;
					esac
					;;
				meta)
					arg3="${msgArr[6]}"
					case "${arg3,,}" in
						list)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Lists any known meta dat associated with your account."
							;;
						add)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Adds a string of meta data to your account. Format is: \"SET META ADD foo=bar\""
							;;
						del|delete|remove)
							echo "(${arg1,,})->(${arg2,,})->(${arg3,,}) => Removes a string of meta data from your account. Note that wild cards are not accepted, the string must be an exact match. Format is: \"SET META DEL foo=bar\""
							;;
						*)
							echo "(${arg1,,})->(${arg2,,}) => Allows you to handle meta data associated with your account. Usually this data is utilized by modules (i.e. the Twitch.tv module [See modules/twitch.sh]). Any applicable modules should tell you the proper format to add meta data with in their help topic."
							;;
					esac
					;;
				removeacct|removeaccount)
					echo "(${arg1,,})->(${arg2,,}) => Begins the two-step removal process of a registered account. Format is: \"SET REMOVEACCT\". To cancel an account removal prior to the second step, use: \"SET REMOVEACCT cancel\""
					;;
				*)
					echo "(${arg1,,}) => Allows you to set certain items related to your account. Sub-commands are: Password, Clones, AllowedHost, Meta, RemoveAcct, RemoveAccount"
					;;
			esac
			;;
		*)
			if egrep -q "^modForm=(.*\"${arg1,,}\".*)$" var/.mods/*.sh; then
				helpFile="$(egrep "^modForm=(.*\"${arg1,,}\".*)$" var/.mods/*.sh /dev/null)"
				helpFile="${helpFile%%:*}"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			elif -e "var/.mods/${arg1,,}.sh"; then
				helpFile="var/.mods/${arg1,,}.sh"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			elif -e "var/.mods/${arg1,,}"; then
				helpFile="var/.mods/${arg1,,}"
				helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
				helpLine="${helpLine#modHelp=\"}"
				helpLine="${helpLine%\"}"
				echo "(${arg1,,}) => ${helpLine} (Provided by ${helpFile##*/} module)"
			else
				echo "No such help topic available"
			fi
			;;
	esac
else
	# Could it match case insensitive?
	if egrep -q "^modForm=(.*\"${arg1}\".*)$" var/.mods/*.sh; then
		helpFile="$(egrep "^modForm=(.*\"${arg1}\".*)$" var/.mods/*.sh /dev/null)"
		helpFile="${helpFile%%:*}"
		helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
		helpLine="${helpLine#modHelp=\"}"
		helpLine="${helpLine%\"}"
		echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
	elif [[ -e "var/.mods/${arg1}.sh" ]]; then
		helpFile="var/.mods/${arg1}.sh"
		helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
		helpLine="${helpLine#modHelp=\"}"
		helpLine="${helpLine%\"}"
		echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
	elif [[ -e "var/.mods/${arg1}" ]]; then
		helpFile="var/.mods/${arg1}"
		helpLine="$(egrep "^modHelp=\"" "${helpFile}")"
		helpLine="${helpLine#modHelp=\"}"
		helpLine="${helpLine%\"}"
		echo "(${arg1}) => ${helpLine} (Provided by ${helpFile##*/} module)"
	else
		echo "No such help topic available"
	fi
fi

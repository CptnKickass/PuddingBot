#!/usr/bin/env bash

pisgUserPath="/home/goose/bin/pisg/freenode/users.cfg"
pisgOptPath="/home/goose/bin/pisg/freenode/options.cfg"
pisgChanPath="/home/goose/bin/pisg/freenode/channels.cfg"
pisgConfPath="/home/goose/bin/pisg/freenode.cfg"

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("pisg")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=()
	if [[ "${#apis[@]}" -ne "0" ]]; then
		if [[ -e "api.conf" ]]; then
			for i in "${apis[@]}"; do
				val="$(egrep "^${i}" "api.conf")"
				val="${val#${i}=\"}"
				val="${val%\"}"
				if [[ -z "${val}" ]]; then
					echo -e "Missing api key \"${red}${i}${reset}\"! Exiting."
					apiFail="1"
				fi
			done
		else
			path="$(pwd)"
			path="${path##*/}"
			path="./${path}/${0##*/}"
			echo "Unable to locate \"api.conf\"!"
			echo "(Are you running the dependency check from the main directory?)"
			echo "(ex: ${path} --dep-check)"
			exit 255
		fi
	fi
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

modHook="Prefix"
modForm=("pisg")
modFormCase=""
modHelp="Handles channel/user management of pisg statistics"
modFlag="m"
# 0                               1       2      3         4    5   6    7
# goose!goose@captain-kickass.net PRIVMSG #goose :!example here are some parameters
# If you want all the parameters: ${msgArr[@]:4}
# PISG tag format:
# <user nick="goose" alias="Mobilegoose TabletGoose " link="/" pic="/files/koth-small.jpg" bigpic="/files/koth.jpg" sex="m">

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${modFlag}"; then
		user="$(fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $1}')"
		tag="$(fgrep "<user nick=\"${user}\"" "${pisgUserPath}")"
		tagLineNo="$(fgrep -n "<user nick=\"${user}\"" "${pisgUserPath}")"
		tagLineNo="${tagLineNo%%:*}"
		mNick="${user}"
		if fgrep -q " ignore=\"" <<<"${tag}"; then
			ignored="${tag#*\" ignore=\"}"
			ignored="${ignore%%\"*}"
		else
			unset ignored
		fi
		if fgrep -q " alias=\"" <<<"${tag}"; then
			alias="${tag#*\" alias=\"}"
			alias="${alias%%\"*}"
			alias=(${alias})
		else
			unset alias
		fi
		if fgrep -q " link=\"" <<<"${tag}"; then
			link="${tag#*\" link=\"}"
			link="${link%%\"*}"
		else
			unset link
		fi
		if fgrep -q " pic=\"" <<<"${tag}"; then
			pic="${tag#*\" pic=\"}"
			pic="${pic%%\"*}"
		else
			unset pic
		fi
		if fgrep -q " sex=\"" <<<"${tag}"; then
			sex="${tag#*\" sex=\"}"
			sex="${sex%%\"*}"
		else
			unset sex
		fi
		if [[ -n "${ignored}" ]]; then
			echo "User not found."
		else
			if [[ -z "${msgArr[4]}" ]]; then
				echo "This command requires a parameter. Valid Parameters: (Show|List) (Add|Set) (Del|Rem|Delete|Remove)"
			else
				case "${msgArr[4],,}" in
					show|list)
					if [[ -z "${tag}" ]]; then
						echo "You do not appear to have a pisg tag."
					else
						echo "Nick: ${mNick}"
						if [[ -n "${alias[@]}" ]]; then
							echo "Aliases: ${alias[@]}"
						fi
						if [[ -n "${link}" ]]; then
							echo "Link: ${link}"
						fi
						if [[ -n "${pic}" ]]; then
							echo "Pic: ${pic}"
						fi
						if [[ -n "${sex}" ]]; then
							echo "Gender: ${sex}"
						fi
					fi
					;;
					set|add)
					case "${msgArr[5],,}" in
						nick)
						echo "Your main nick cannot be changed from your account name in Pudding."
						;;
						alias|aliases)
						newAlias="${msgArr[@]:6}"
						newAlias="${newAlias//\"/}"
						newAlias=(${newAlias})
						if [[ "${#newAlias[@]}" -ne "0" ]]; then
							while read d; do
								a="${d#*\" alias=\"}"
								a="${a%%\"*}"
								b="${d#<user nick=\"}"
								b="${b%%\"*}"
								for c in "${newAlias[@]}"; do
									if fgrep -q -i "${c}" <<<"${a}" || fgrep -q -i "${c}" <<<"${b}"; then
										inUse="1"
										inUseItem="${c}"
										break
									else
										inUse="0"
									fi
								done
								if [[ "${inUse}" -eq "1" ]]; then
									break
								fi
							done < <(fgrep " alias=\"" "${pisgUserPath}" | fgrep -v "<user nick=\"${user}\"")

							if [[ "${inUse}" -eq "0" ]]; then
								newTag="<user nick=\"${mNick}\" alias=\"${newAlias[@]}\">"
								if [[ -n "${link}" ]]; then
									newTag="${newTag%>} link=\"${link}\">"
								fi
								if [[ -n "${pic}" ]]; then
									newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
								fi
								if [[ -n "${sex}" ]]; then
									newTag="${newTag%>} sex=\"${sex}\">"
								fi
								if [[ -z "${alias[@]}" ]]; then
									echo "Set new alias(es) to: ${newAlias[@]}"
								else
									for a in "${alias[@]}"; do
										newAlias=(${newAlias[@]/${a}/})
									done
									if [[ "${#newAlias[@]}" -ne "0" ]]; then
										echo "Added alias(es) ${newAlias[@]} to ${alias[@]}"
									else
										echo "You already have those aliases!"
									fi
								fi
								sed -i "${tagLineNo}d" "${pisgUserPath}"
								echo "${newTag}" >> "${pisgUserPath}"
								cat "${pisgUserPath}" > "${pisgConfPath}"
								cat "${pisgOptPath}" >> "${pisgConfPath}"
								cat "${pisgChanPath}" >> "${pisgConfPath}"
							else
								echo "Unable to set new alias tag! Item \"${inUseItem}\" is already claimed by another user."
							fi
						else
							echo "This command requires a parameter."
						fi
						;;
						link)
						newLink="${msgArr[6]}"
						newLink="${newLink//\"/}"
						re="(http(s?):\/\/[^ \"\(\)\<\>]*|\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b)"
						if [[ -n "${newLink}" ]]; then
							if egrep -q -i -o "${re}" <<<"${newLink}"; then
								newTag="<user nick=\"${mNick}\" link=\"${newLink}\">"
								if [[ -n "${alias[@]}" ]]; then
									newTag="${newTag%>} alias=\"${alias[@]}\">"
								fi
								if [[ -n "${pic}" ]]; then
									newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
								fi
								if [[ -n "${sex}" ]]; then
									newTag="${newTag%>} sex=\"${sex}\">"
								fi
								if [[ -z "${link}" ]]; then
									echo "Set new link to: ${newLink}"
								else
									echo "Changed link from: ${link} to: ${newLink}"
								fi
								sed -i "${tagLineNo}d" "${pisgUserPath}"
								echo "${newTag}" >> "${pisgUserPath}"
								cat "${pisgUserPath}" > "${pisgConfPath}"
								cat "${pisgOptPath}" >> "${pisgConfPath}"
								cat "${pisgChanPath}" >> "${pisgConfPath}"
							else
								echo "${newLink} does not appear to be a valid URL or e-mail address."
							fi
						else
							echo "This command requires a parameter."
						fi
						;;
						pic)
						newPic="${msgArr[6]}"
						newPic="${newPic//\"/}"
						re="http(s?):\/\/[^ \"\(\)\<\>]*\.(jpg|jpeg|gif|png)$"
						if [[ -n "${newPic}" ]]; then
							if egrep -q -i -o "${re}" <<<"${newPic}"; then
								newTag="<user nick=\"${mNick}\" pic=\"${newPic}\" bigpic=\"${newPic}\">"
								if [[ -n "${alias[@]}" ]]; then
									newTag="${newTag%>} alias=\"${alias[@]}\">"
								fi
								if [[ -n "${link}" ]]; then
									newTag="${newTag%>} link=\"${link}\">"
								fi
								if [[ -n "${sex}" ]]; then
									newTag="${newTag%>} sex=\"${sex}\">"
								fi
								if [[ -z "${pic}" ]]; then
									echo "Set new pic to: ${newPic}"
								else
									echo "Changed pic from: ${pic} to: ${newPic}"
								fi
								sed -i "${tagLineNo}d" "${pisgUserPath}"
								echo "${newTag}" >> "${pisgUserPath}"
								cat "${pisgUserPath}" > "${pisgConfPath}"
								cat "${pisgOptPath}" >> "${pisgConfPath}"
								cat "${pisgChanPath}" >> "${pisgConfPath}"
							else
								echo "${newPic} does not appear to be a valid URL to an image file (Allowed file types are: PNG, JPG, JPEG, GIF)"
							fi
						else
							echo "This command requires a parameter."
						fi
						;;
						sex|gender)
						newSex="${msgArr[6]:0:1}"
						newSex="${newSex//\"/}"
						if [[ -n "${newSex}" ]]; then
							newSex="${newSex,,}"
							if [[ "${newSex}" =~ [m|f|b] ]]; then
								newTag="<user nick=\"${mNick}\" sex=\"${newSex}\">"
								if [[ -n "${alias[@]}" ]]; then
									newTag="${newTag%>} alias=\"${alias[@]}\">"
								fi
								if [[ -n "${pic}" ]]; then
									newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
								fi
								if [[ -n "${link}" ]]; then
									newTag="${newTag%>} link=\"${link}\">"
								fi
								if [[ -z "${sex}" ]]; then
									echo "Set sex to: ${newSex}"
								else
									echo "Changed sex from: ${sex} to: ${newSex}"
								fi
								sed -i "${tagLineNo}d" "${pisgUserPath}"
								echo "${newTag}" >> "${pisgUserPath}"
								cat "${pisgUserPath}" > "${pisgConfPath}"
								cat "${pisgOptPath}" >> "${pisgConfPath}"
								cat "${pisgChanPath}" >> "${pisgConfPath}"
							else
								echo "${newSex} does not appear to be a valid gender (Genders are: M (Male), F (Female), B (Bot))"
							fi
						else
							echo "This command requires a parameter."
						fi
						;;
						*)
						echo "Invalid parameter. Parameters are: Alias, Link, Pic, Gender"
						;;
					esac
					;;
					del|delete|rem|remove)
					case "${msgArr[5],,}" in
						nick)
						echo "Your main nick cannot be removed."
						;;
						alias|aliases)
						if [[ -n "${alias[@]}" ]]; then
							if [[ -z "${msgArr[@]:6}" ]]; then
								newTag="<user nick=\"${mNick}\">"
								echo "Removed all aliases from your user."
								if [[ -n "${link}" ]]; then
									newTag="${newTag%>} link=\"${link}\">"
								fi
								if [[ -n "${pic}" ]]; then
									newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
								fi
								if [[ -n "${sex}" ]]; then
									newTag="${newTag%>} sex=\"${sex}\">"
								fi
								sed -i "${tagLineNo}d" "${pisgUserPath}"
								echo "${newTag}" >> "${pisgUserPath}"
								cat "${pisgUserPath}" > "${pisgConfPath}"
								cat "${pisgOptPath}" >> "${pisgConfPath}"
								cat "${pisgChanPath}" >> "${pisgConfPath}"
							else
								unset unsetArr
								aliasArr=(${msgArr[@]:6})
								n="0"
								for a in "${aliasArr[@]}"; do
									for b in "${alias[@]}"; do
										if [[ "${a,,}" == "${b,,}" ]]; then
											unsetArr+=(${n})
										fi
										(( n++ ))
									done
								done
								if [[ "${#unsetArr[@]}" -ne "0" ]]; then
									for a in "${unsetArr[@]}"; do
										unset alias[${a}]
									done
								fi
								if [[ "${#alias[@]}" -ne "0" ]]; then
									newTag="<user nick=\"${mNick}\" alias=\"${alias[@]}\">"
									echo "Changed your alias to ${alias[@]}"
									if [[ -n "${link}" ]]; then
										newTag="${newTag%>} link=\"${link}\">"
									fi
									if [[ -n "${pic}" ]]; then
										newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
									fi
									if [[ -n "${sex}" ]]; then
										newTag="${newTag%>} sex=\"${sex}\">"
									fi
									sed -i "${tagLineNo}d" "${pisgUserPath}"
									echo "${newTag}" >> "${pisgUserPath}"
									cat "${pisgUserPath}" > "${pisgConfPath}"
									cat "${pisgOptPath}" >> "${pisgConfPath}"
									cat "${pisgChanPath}" >> "${pisgConfPath}"
								else
									echo "No changes to make!"
								fi
							fi
						else
							echo "No alias tag to delete from your user!"
						fi
						;;
						link)
						if [[ -n "${link}" ]]; then
							newTag="<user nick=\"${mNick}\">"
							if [[ -n "${alias[@]}" ]]; then
								newTag="${newTag%>} alias=\"${alias[@]}\">"
							fi
							if [[ -n "${pic}" ]]; then
								newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
							fi
							if [[ -n "${sex}" ]]; then
								newTag="${newTag%>} sex=\"${sex}\">"
							fi
							echo "Removed link tag from your user."
							sed -i "${tagLineNo}d" "${pisgUserPath}"
							echo "${newTag}" >> "${pisgUserPath}"
							cat "${pisgUserPath}" > "${pisgConfPath}"
							cat "${pisgOptPath}" >> "${pisgConfPath}"
							cat "${pisgChanPath}" >> "${pisgConfPath}"
						else
							echo "No link tag to delete from your user!"
						fi
						;;
						pic)
						if [[ -n "${pic}" ]]; then
							newTag="<user nick=\"${mNick}\">"
							if [[ -n "${alias[@]}" ]]; then
								newTag="${newTag%>} alias=\"${alias[@]}\">"
							fi
							if [[ -n "${sex}" ]]; then
								newTag="${newTag%>} sex=\"${sex}\">"
							fi
							if [[ -n "${link}" ]]; then
								newTag="${newTag%>} link=\"${link}\">"
							fi
							echo "Removed gender tag from your user."
							sed -i "${tagLineNo}d" "${pisgUserPath}"
							echo "${newTag}" >> "${pisgUserPath}"
							cat "${pisgUserPath}" > "${pisgConfPath}"
							cat "${pisgOptPath}" >> "${pisgConfPath}"
							cat "${pisgChanPath}" >> "${pisgConfPath}"
						else
							echo "No gender tag to delete from your user!"
						fi
						;;
						sex|gender)
						if [[ -n "${sex}" ]]; then
							newTag="<user nick=\"${mNick}\">"
							if [[ -n "${alias[@]}" ]]; then
								newTag="${newTag%>} alias=\"${alias[@]}\">"
							fi
							if [[ -n "${pic}" ]]; then
								newTag="${newTag%>} pic=\"${pic}\" bigpic=\"${pic}\">"
							fi
							if [[ -n "${link}" ]]; then
								newTag="${newTag%>} link=\"${link}\">"
							fi
							echo "Removed gender tag from your user."
							sed -i "${tagLineNo}d" "${pisgUserPath}"
							echo "${newTag}" >> "${pisgUserPath}"
							cat "${pisgUserPath}" > "${pisgConfPath}"
							cat "${pisgOptPath}" >> "${pisgConfPath}"
							cat "${pisgChanPath}" >> "${pisgConfPath}"
						else
							echo "No gender tag to delete from your user!"
						fi
						;;
						*)
						echo "Invalid parameter. Parameters are: Alias, Link, Pic, Gender"
						;;
					esac
					;;
					*)
					echo "Invalid parameter. Parameters are: (Show|List), (Set|Add), (Del|Delete|Rem|Remove)"
					;;
				esac
			fi
		fi
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

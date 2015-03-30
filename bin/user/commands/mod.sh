#!/usr/bin/env bash
reqFlag="M"

loggedIn="$(fgrep -c "${senderUser}@${senderHost}" "var/.admins")"
if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" "var/.admins" | awk '{print $3}' | fgrep -q "${reqFlag}"; then
		modCom="${msgArr[4]}"
		unset modComItem
		case "${modCom,,}" in
			status)
				modComItem="$(read -r one two three four five rest <<<"${message}"; echo "${rest}")"
				modComItem=(${modComItem})
				for arrItem in ${modComItem[@]}; do
					if ! egrep -q "\.sh$" <<<"${arrItem}"; then
						arrItem="${arrItem}.sh"
					fi
					if [[ -z "${arrItem}" ]]; then
						echo "This command requires a parameter (module name)"
					elif [[ -e "var/.mods/${arrItem}" ]]; then
						echo "${arrItem} is loaded"
					else
						echo "${arrItem} is not loaded"
					fi
				done
			;;
			load)
				modComItem="$(read -r one two three four five rest <<<"${message}"; echo "${rest}")"
				modComItem=(${modComItem})
				for arrItem in ${modComItem[@]}; do
					if ! egrep -q "\.sh$" <<<"${arrItem}"; then
						arrItem="${arrItem}.sh"
					fi
					if [[ -e "var/.mods/${arrItem}" ]]; then
						echo "${arrItem} is already loaded. Do you mean reload, or unload?"
					elif [[ -e "modules/${arrItem}" ]]; then
						if [[ "$(source ./modules/${arrItem} --dep-check)" == "ok" ]]; then
							cp "modules/${arrItem}" "var/.mods/${arrItem}"
							echo "modules/${arrItem} loaded"
						else
							echo "Unable to load modules/${arrItem}! ($(source ./modules/${arrItem} --dep-check))"
						fi
					elif [[ -e "contrib/${arrItem}" ]]; then
						if [[ "$(source ./contrib/${arrItem} --dep-check)" == "ok" ]]; then
							cp "contrib/${arrItem}" "var/.mods/${arrItem}"
							echo "contrib/${arrItem} loaded"
						else
							echo "Unable to load contrib/${arrItem}! ($(source ./contrib/${arrItem} --dep-check))"
						fi
					else
						echo "${arrItem} does not appear to exist in \"modules/\" or \"contrib/\". Remember, on unix based file systems, case sensitivity matters!"
					fi
				done
			;;
			unload)
				modComItem="$(read -r one two three four five rest <<<"${message}"; echo "${rest}")"
				modComItem=(${modComItem})
				for arrItem in ${modComItem[@]}; do
					if ! egrep -q "\.sh$" <<<"${arrItem}"; then
						arrItem="${arrItem}.sh"
					fi
					if [[ -e "var/.mods/${arrItem}" ]]; then
						rm "var/.mods/${arrItem}"
						if [[ -e "var/.mods/${arrItem}" ]]; then
							echo "Unable to unload ${arrItem}!"
						else
							echo "${arrItem} unloaded"
						fi
					else
						echo "${arrItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
					fi
				done
			;;
			reload)
				modComItem="$(read -r one two three four five rest <<<"${message}"; echo "${rest}")"
				modComItem=(${modComItem})
				for arrItem in ${modComItem[@]}; do
					if ! egrep -q "\.sh$" <<<"${arrItem}"; then
						arrItem="${arrItem}.sh"
					fi
					if [[ -e "var/.mods/${arrItem}" ]]; then
						rm "var/.mods/${arrItem}"
						if [[ -e "var/.mods/${arrItem}" ]]; then
							echo "Unable to unload ${arrItem}!"
						else
							echo "${arrItem} unloaded"
							if [[ -e "modules/${arrItem}" ]]; then
								if [[ "$(source ./modules/${arrItem} --dep-check)" == "ok" ]]; then
									cp "modules/${arrItem}" "var/.mods/${arrItem}"
									echo "modules/${arrItem} loaded"
								else
									echo "Unable to load modules/${arrItem}! ($(source ./modules/${arrItem} --dep-check))"
								fi
							elif [[ -e "contrib/${arrItem}" ]]; then
								if [[ "$(source ./contrib/${arrItem} --dep-check)" == "ok" ]]; then
									cp "contrib/${arrItem}" "var/.mods/${arrItem}"
									echo "contrib/${arrItem} loaded"
								else
									echo "Unable to load contrib/${arrItem}! ($(source ./contrib/${arrItem} --dep-check))"
								fi
							else
								echo "Unable to load ${arrItem}!"
							fi
						fi
					else
						echo "${arrItem} does not appear to be loaded. Remember, on unix based file systems, case sensitivity matters!"
					fi
				done
			;;
			reloadall)
				unset modOutArr
				for modComItem in var/.mods/*.sh; do
					modComItem="${modComItem##*/}"
					rm "var/.mods/${modComItem}"
					if [[ -e "var/.mods/${modComItem}" ]]; then
						modOutArr+=("Unable to unload ${modComItem} ->")
					else
						modOutArr+=("${modComItem} unloaded ->")
						if [[ -e "modules/${modComItem}" ]]; then
							cp "modules/${modComItem}" "var/.mods/${modComItem}"
							modOutArr+=("modules/${modComItem} loaded |")
						elif [[ -e "contrib/${modComItem}" ]]; then
							cp "contrib/${modComItem}" "var/.mods/${modComItem}"
							modOutArr+=("contrib/${modComItem} loaded |")
						else
							modOutArr+=("Unable to load ${modComItem} |")
						fi
					fi
				done
				modOutLine="${modOutArr[@]}"
				echo "${modOutLine% |*}"
			;;
			list)
				unset modArr
				modLineArr=0
				while read modLine; do
					modArr[ ${modLineArr} ]="${modLine}"
					(( modLineArr++ ))
				done < <(ls -1 var/.mods/)
				echo "${modArr[@]}"
			;;
			*)
				echo "Invalid command. Valid options: Status, Load, Unload, Reload, ReloadAll, List"
			;;
		esac
	else
		echo "You do not have sufficient permissions for this command"
	fi
else
	echo "You must be logged in to use this command"
fi

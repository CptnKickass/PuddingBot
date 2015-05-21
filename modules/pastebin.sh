#!/usr/bin/env bash

# Copyright (C) 2014 Elan Ruusamäe

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

## Config
# Default number of lines to paste
n="100"

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=("pbUrl" "pbApiKey")
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
modForm=("pb" "paste" "pastebin")
modFormCase=""
modHelp="Provides spell check functionality via ispell"
modFlag="m"
loggedIn="$(fgrep -c "${senderUser}@${senderHost}" var/.admins)"

if [[ "${loggedIn}" -eq "1" ]]; then
	if fgrep "${senderUser}@${senderHost}" var/.admins | awk '{print $3}' | fgrep -q "${modFlag}"; then
		# paste. take input from stdin
		pastebin() {
			# do paste
			curl -s "${pbUrl}?apikey=${pbApiKey}" \
				${title+-F title="$title"} \
				${name+-F name="$name"} \
				${private+-F private="$private"} \
				${language+-F lang="$language"} \
				${expire+-F expire="$expire"} \
				${reply+-F reply="$reply"} \
				-F 'text=<-'
		}
		unset title
		unset private
		unset language
		unset expire
		unset reply
		
		if [[ -n "${msgArr[4]}" ]]; then
			re='[0-9]+'
			if [[ "${msgArr[4]}" =~ ${re} ]]; then
				n="${msgArr[4]}"
			else
				echo "[Pastebin] ${msgArr[4]} doesn't appear to be a valid number. Defaulting to ${n} lines."
			fi
		fi
		
		title="${n} lines of IRC history from ${senderTarget}"
		name="${senderNick}"
		language="text"
		paste="$(tail -n ${n} "logs/${senderTarget,,}.log")"
		link="$(echo -n "${paste}" | pastebin)"
		echo "[Pastebin] ${link}"
	else
		echo "[Pastebin] You do not have sufficient permissions for this command"
	fi
else
	echo "[Pastebin] You must be logged in to use this command"
fi

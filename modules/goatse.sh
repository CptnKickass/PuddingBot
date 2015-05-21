#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
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
modForm=("goatse")
modFormCase=""
modHelp="Try it and see what happens (Fair warning: NSFW)"
modFlag="m"
g=("* g o a t s e x * g o a t s e x * g o a t s e x *" "g                                               g" "o /     \\             \\            /    \\       o" "a|       |             \\          |      |      a" "t|       \`.             |         |       :     t" "s\`        |             |        \\|       |     s" "e \\       | /       /  \\\\\\   --__ \\\\       :    e" "x  \\      \\/   _--~~          ~--__| \\     |    x" "*   \\      \\_-~                    ~-_\\    |    *" "g    \\_     \\        _.--------.______\\|   |    g" "o      \\     \\______// _ ___ _ (_(__>  \\   |    o" "a       \\   .  C ___)  ______ (_(____>  |  /    a" "t       /\\ |   C ____)/      \\ (_____>  |_/     t" "s      / /\\|   C_____)       |  (___>   /  \\    s" "e     |   (   _C_____)\\______/  // _/ /     \\   e" "x     |    \\  |__   \\\\_________// (__/       |  x" "*    | \\    \\____)   \`----   --'             |  *" "g    |  \\_          ___\\       /_          _/ | g" "o   |              /    |     |  \\            | o" "a   |             |    /       \\  \\           | a" "t   |          / /    |         |  \\           |t" "s   |         / /      \\__/\\___/    |          |s" "e  |           /        |    |       |         |e" "x  |          |         |    |       |         |x" "* g o a t s e x * g o a t s e x * g o a t s e x *")
for l in "${g[@]}"; do
	echo "[Goatse] ${l}"
done

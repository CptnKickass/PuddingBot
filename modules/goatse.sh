#!/usr/bin/env bash

## Config
# None for this script

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "${depFail}" -eq "1" ]; then
			exit 1
		else
			echo "ok"
			exit 0
		fi
	else
		echo "ok"
		exit 0
	fi
fi

modHook="Prefix"
modForm=("goatse")
modFormCase=""
modHelp="Try it and see what happens (Fair warning: NSFW)"
modFlag="m"
echo "* g o a t s e x * g o a t s e x * g o a t s e x *"
echo "g                                               g"
echo "o /     \\             \\            /    \\       o"
echo "a|       |             \\          |      |      a"
echo "t|       \`.             |         |       :     t"
echo "s\`        |             |        \\|       |     s"
echo "e \\       | /       /  \\\\\\   --__ \\\\       :    e"
echo "x  \\      \\/   _--~~          ~--__| \\     |    x"
echo "*   \\      \\_-~                    ~-_\\    |    *"
echo "g    \\_     \\        _.--------.______\\|   |    g"
echo "o      \\     \\______// _ ___ _ (_(__>  \\   |    o"
echo "a       \\   .  C ___)  ______ (_(____>  |  /    a"
echo "t       /\\ |   C ____)/      \\ (_____>  |_/     t"
echo "s      / /\\|   C_____)       |  (___>   /  \\    s"
echo "e     |   (   _C_____)\\______/  // _/ /     \\   e"
echo "x     |    \\  |__   \\\\_________// (__/       |  x"
echo "*    | \\    \\____)   \`----   --'             |  *"
echo "g    |  \\_          ___\\       /_          _/ | g"
echo "o   |              /    |     |  \\            | o"
echo "a   |             |    /       \\  \\           | a"
echo "t   |          / /    |         |  \\           |t"
echo "s   |         / /      \\__/\\___/    |          |s"
echo "e  |           /        |    |       |         |e"
echo "x  |          |         |    |       |         |x"
echo "* g o a t s e x * g o a t s e x * g o a t s e x *"
exit 0

#!/usr/bin/env bash

## Config
# Config options go here

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	# Dependencies go in this array
	# Dependencies already required by the controller script:
	# read fgrep egrep echo cut sed ps awk
	# Format is: deps=("foo" "bar")
	deps=()
	if [ "${#deps[@]}" -ne "0" ]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [ "$depFail" -eq "1" ]; then
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

# Hook should either be "Prefix" or "Format". Prefix will patch whatever
# the $comPrefix is, i.e. !command. Format will match a message specific
# format, i.e. the sed module.
hook="Prefix"

# This is where the module source should start
msg="$@"
msg="${msg#${0} }"
com="$(echo "$msg" | awk '{print $4}')"
com="${com:2}"
case "$com" in
	goatse)
		echo "* g o a t s e x * g o a t s e x * g o a t s e x *" >> $output
		echo "g                                               g" >> $output
		echo "o /     \\             \\            /    \\       o" >> $output
		echo "a|       |             \\          |      |      a" >> $output
		echo "t|       \\`.             |         |       :     t" >> $output
		echo "s\\`        |             |        \\|       |     s" >> $output
		echo "e \\       | /       /  \\\\\\   --__ \\\\       :    e" >> $output
		echo "x  \\      \\/   _--~~          ~--__| \\     |    x" >> $output
		echo "*   \\      \\_-~                    ~-_\\    |    *" >> $output
		echo "g    \\_     \\        _.--------.______\\|   |    g" >> $output
		echo "o      \\     \\______// _ ___ _ (_(__>  \\   |    o" >> $output
		echo "a       \\   .  C ___)  ______ (_(____>  |  /    a" >> $output
		echo "t       /\\ |   C ____)/      \\ (_____>  |_/     t" >> $output
		echo "s      / /\\|   C_____)       |  (___>   /  \\    s" >> $output
		echo "e     |   (   _C_____)\\______/  // _/ /     \\   e" >> $output
		echo "x     |    \\  |__   \\\\_________// (__/       |  x" >> $output
		echo "*    | \\    \\____)   \\`----   --'             |  *" >> $output
		echo "g    |  \\_          ___\\       /_          _/ | g" >> $output
		echo "o   |              /    |     |  \\            | o" >> $output
		echo "a   |             |    /       \\  \\           | a" >> $output
		echo "t   |          / /    |         |  \\           |t" >> $output
		echo "s   |         / /      \\__/\\___/    |          |s" >> $output
		echo "e  |           /        |    |       |         |e" >> $output
		echo "x  |          |         |    |       |         |x" >> $output
		echo "* g o a t s e x * g o a t s e x * g o a t s e x *" >> $output
	;;
esac
exit 0

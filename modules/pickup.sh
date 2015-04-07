#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=()
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
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

modHook="prefix"
modForm=("pickup" "pul")
modFormCase="No"
modHelp="Hits on users"
modFlag="m"

responseArr=("I bet your name's Mickey, 'cause you're so fine." "Hey, pretty mama. You smell kinda pretty, wanna smell me?" "I better get out my library card, 'cause I'm checkin' you out." "If you were a booger, I'd pick you." "If I could rearrange the alphabet, I would put U and I together." "I've been bad, take me to your room." "I think Heaven's missing an angel." "That shirt is very becoming on you. If I was on you, I'd be coming too." "Are you a parking ticket? Because you've got FINE written all over you." "Nice butt." "Did you ever realize that screw rhymes with me and you?" "I'm gay but you might just turn me straight." "I love you like a fat kid loves cake." "I lost my virginity, can I have yours?" "Do you believe in love at first sight? Or should I walk by again...?" "Girl, did it hurt when you fell from heaven? Cause your face is all sorts of jacked up." "I'm going to have sex with you tonight, you might as well be there to enjoy it." "Do you have a map? I think I just got lost in your eyes." "Want to see my good side? Hah, that was a trick question, all I have are good sides." "Do you work at subway? Cause you just gave me a footlong." "You look like a woman who appreciates the finer things in life. Come over here and feel my velour bedspread." "Now you're officially my woman. Kudos! I can't say I don't envy you." "I find that the most erotic part of a woman is the boobies." "I wish I was one of your tears, so I could be born in your eye, run down your cheek, and die on your lips." "If you want to climb aboard the Love Train, you've got to stand on the Love Tracks. But you might just get smushed by a very sensual cow-catcher." "It’s a good thing I wore my gloves today; otherwise, you’d be too hot to handle." "Lets say you and I knock some very /sensual/ boots." "I lost my phone number, can I have yours?" "Does this rag smell like chloroform to you?" "I'm here, where are your other two wishes?" "Are you a parking ticket? Cause you have FINE written all over you." "Do you have a mirror in your jeans? Cause I can see myself in your ass." "Apart from being sexy, what do you do for a living?" "Hi, I'm Mr. Right. Someone said you were looking for me." "Eyy bby wun sum fuk?" "You got something on your chest: My eyes." "Are you from Tennessee? Cause you're the only TEN I see." "Are you an alien? Because you just abducted my heart." "Excuse me, but I think you dropped something. MY JAW!" "If I followed you home, would you keep me?" "I wish you were a Pony Carousel outside Walmart, so I could ride you all day long for a quarter." "I'm so sorry, it seems I've lost my keys. Do you mind if I check your pants?" "Where have you been all my life?" "I'm just a love machine, and I don't work for nobody but you." "Do you live on a chicken farm? Because you sure know how to raise cocks." "Are you wearing space pants? Because your ass is out of this world." "You are almost as beautiful as my sister. But well, you know, that’s illegal." "Nice legs. What time do they open?" "Are you lost? Because it’s so strange to see an angel so far from heaven." "Your daddy must have been a baker, because you've got a nice set of buns." "You're so beautiful that last night you made me forget my pickup line." "I've never seen such dark eyes with so much light in them." "I think we should just be friends with sexual tension." "Whenever I see you I feel like a dog dying to get out of the car." "If I'd have held you any closer I'd be in back of you." "I wish I were on Facebook so I could poke you." "Are you my appendix? I don't know what you do or how you work but I feel like I should take you out." "I want you like JFK wanted a car with a roof.")
if [[ -z "${msgArr[4]}" ]]; then
	echo "${responseArr[${RANDOM} % ${#responseArr[@]} ]] }"
else
	echo "${msgArr[4]}: ${responseArr[${RANDOM} % ${#responseArr[@]} ]] }"
fi

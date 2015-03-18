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
modForm=("attack" "abuse")
modFormCase=""
modHelp="Abuses a targeted user, or random user if no target is given"
modFlag="m"

temp=("{hits} {user} with a {item}." "{hits} {user} around a bit with a {item}." "{throws} a {item} at {user}." "{throws} a few {item_plural} at {user}." "grabs a {item} and {throws} it in {user}'s face." "launches a {item} in {user}'s general direction." "sits on {user}'s face while slamming a {item} into their crotch." "starts slapping {user} silly with a {item}." "holds {user} down and repeatedly {hits} them with a {item}." "prods {user} with a {item}." "picks up a {item} and {hits} {user} with it." "ties {user} to a chair and {throws} a {item} at them." "{hits} {user} {where} with a {item}." "ties {user} to a pole and whips them with a {item}." "smacks {user} in the face with a burlap sack full of broken glass." "swaps {user}'s shampoo with glue." "installs Windows Vista on {user}'s computer." "forces {user} to use perl for 3 weeks." "registers {user}'s name with 50 known spammers." "resizes {user}'s console to 40x24." "takes {user}'s drink." "dispenses {user}'s email address to a few hundred 'bulk mailing services'." "pokes {user} in the eye." "beats {user} senseless with a 50lb Linux manual." "cats /dev/random into {user}'s ear." "signs {user} up for AOL." "downvotes {user} on Reddit." "enrolls {user} in Visual Basic 101." "sporks {user}." "drops a truckload of support tickets on {user}." "judo chops {user}." "sets {user}'s resolution to 800x600." "formats {user}'s harddrive to fat12." "rm -rf's {user}." "stabs {user}." "makes {user} learn C++." "steals {user}'s mojo." "strangles {user} with a doohicky mouse cord." "whacks {user} with the cluebat." "sells {user} on EBay." "drops creepers on {user}'s house." "throws all of {user}'s diamond gear into lava." "uses {user} as a biological warfare study." "uses the 'Customer Appreciation Bat' on {user}." "puts {user} in the Total Perspective Vortex." "saves all of {user}'s files on a Magical Chinese Looping Hard Drive." "casts {user} into the fires of Mt. Doom." "gives {user} a melvin." "turns {user} over to the Fun Police." "turns over {user} to Agent Smith to be 'bugged'." "takes away {user}'s internet connection." "pushes {user} past the Shoe Event Horizon." "counts '1, 2, 5... er... 3!' and hurls the Holy Handgrenade Of Antioch at {user}." "puts {user} in a nest of camel spiders." "puts 'alias vim=emacs' in {user}'s /etc/profile." "uninstalls every web browser from {user}'s system." "signs {user} up for getting hit on the head lessons." "makes {user} try to set up a Lexmark printer." "fills {user}'s eyedrop bottle with lime juice." "casts {user} into the fires of Mt. Doom." "gives {user} a Flying Dutchman." "rips off {user}'s arm, and uses it to beat them to death." "pierces {user}'s nose with a rusty paper hole puncher." "pokes {user} with a rusty nail." "puts sugar between {user}'s bedsheets." "pours sand into {user}'s breakfast." "mixes epoxy into {user}'s toothpaste." "puts Icy-Hot in {user}'s lube container." "forces {user} to use a Commodore 64 for all their word processing." "puts {user} in a room with several heavily armed manic depressives." "makes {user} watch reruns of \"Blue's Clues\"." "puts lye in {user}'s coffee." "tattoos the Windows symbol on {user}'s ass." "lets Borg have his way with {user}." "signs {user} up for line dancing classes at the local senior center." "wakes {user} out of a sound sleep with some brand new nipple piercings." "gives {user} a 2 gauge Prince Albert." "forces {user} to eat all their veggies." "covers {user}'s toilet paper with lemon-pepper." "fills {user}'s ketchup bottle with Dave's Insanity sauce." "forces {user} to stare at an incredibly frustrating and seemingly never-ending IRC political debate." "knocks two of {user}'s teeth out with a 2x4." "removes Debian from {user}'s system." "switches {user} over to CentOS." "uses {user}'s iPod for skeet shooting practice." "gives {user}'s phone number to Borg." "posts {user}'s IP, username(s), and password(s) on 4chan." "forces {user} to use words like 'irregardless' and 'administrate' (thereby sounding like a real dumbass)." "tickles {user} until they wet their pants and pass out." "replaces {user}'s KY with elmer's clear wood glue." "replaces {user}'s TUMS with alka-seltzer tablets." "squeezes habanero pepper juice into {user}'s tub of vaseline." "forces {user} to learn the Win32 API." "gives {user} an atomic wedgie." "ties {user} to a chair and forces them to listen to 'N Sync at full blast." "forces {user} to use notepad for text editing." "frowns at {user} really, really hard." "jabs a hot lighter into {user}'s eye sockets." "forces {user} to browse the web with IE6." "takes {user} out at the knees with a broken pool cue." "forces {user} to listen to emo music." "lets a few creepers into {user}'s house." "signs {user} up for the Iowa State Ferret Legging Championship." "attempts to hotswap {user}'s RAM." "dragon punches {user}." "puts railroad spikes into {user}'s side." "replaces {user}'s lubricant with liquid weld." "replaces {user}'s stress pills with rat poison pellets." "replaces {user}'s itch cream with hair removal cream." "does the Australian Death Grip on {user}." "dances upon the grave of {user}'s ancestors." "farts loudly in {user}'s general direction." "flogs {user} with stinging nettle." "hands {user} a poison ivy joint.")
itemSingle=("cast iron skillet" "large trout" "baseball bat" "cricket bat" "wooden cane" "nail" "printer" "shovel" "pair of trousers" "CRT monitor" "diamond sword" "baguette" "physics textbook" "toaster" "portrait of Richard Stallman" "television" "mau5head" "five ton truck" "roll of duct tape" "book" "laptop" "old television" "sack of rocks" "rainbow trout" "cobblestone block" "lava bucket" "rubber chicken" "spiked bat" "gold block" "fire extinguisher" "heavy rock" "chunk of dirt")
itemPlural=("cast iron skillets" "large trouts" "baseball bats" "wooden canes" "nails" "printers" "shovels" "pairs of trousers" "CRT monitors" "diamond swords" "baguettes" "physics textbooks" "toasters" "portraits of Richard Stallman" "televisions" "mau5heads" "five ton trucks" "rolls of duct tape" "books" "laptops" "old televisions" "sacks of rocks" "rainbow trouts" "cobblestone blocks" "lava buckets" "rubber chickens" "spiked bats" "gold blocks" "fire extinguishers" "heavy rocks" "chunks of dirt")
throw=("throws" "flings" "chucks")
hits=("hits" "whacks" "slaps" "smacks")
location=("in the chest" "on the head" "on the bum")

if [ -z "${msgArr[4]}" ]; then
	echo "This command can't attack random people yet. Please specify a target."
else
	attack="${temp[${RANDOM} % ${#temp[@]} ] }"
	if [[ "${msgArr[4],,}" == "${nick,,}" ]]; then
		attack="${attack//\{user\}/${senderNick}}"
	else
		attack="${attack//\{user\}/${msgArr[@]:4}}"
	fi
	if fgrep -q "{item}" <<<"${attack}"; then
		item="${itemSingle[${RANDOM} % ${#itemSingle[@]} ] }"
		attack="${attack//\{item\}/${item}}"
	fi
	if fgrep -q "{item_plural}" <<<"${attack}"; then
		items="${itemPlural[${RANDOM} % ${#itemPlural[@]} ] }"
		attack="${attack//\{item_plural\}/${items}}"
	fi
	if fgrep -q "{throws}" <<<"${attack}"; then
		throw="${throw[${RANDOM} % ${#throw[@]} ] }"
		attack="${attack//\{throws\}/${throw}}"
	fi
	if fgrep -q "{hits}" <<<"${attack}"; then
		hits="${hits[${RANDOM} % ${#hits[@]} ] }"
		attack="${attack//\{hits\}/${hits}}"
	fi
	if fgrep -q "{where}" <<<"${attack}"; then
		location="${location[${RANDOM} % ${#location[@]} ] }"
		attack="${attack//\{where\}/${location}}"
	fi
	echo "ACTION ${attack}"
fi

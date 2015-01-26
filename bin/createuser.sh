#!/usr/bin/env bash
echo "-+| Create A User |+-"
echo ""
read -p "Please enter desired username: " username
username="${username,,}"
username="${username// /}"
while egrep -q "^user=\"${username}\"$" users/*.conf; do
	echo "Username already in use. Please choose a new username."
	read -p "Please enter desired username: " username
	username="${username,,}"
	username="${username// /}"
done
echo "Selected username: ${username}"
echo ""
read -p "Please enter desired password: " password
hash="$(echo "${password}" | md5sum | awk '{print $1}')"
hash2="$(echo "${hash}" | md5sum | awk '{print $1}')"
passHash="${hash}${hash2}"
echo "Hash of \"${password}\": ${passHash}"
echo ""
re='^[0-9]+$'
echo "Please enter desired number of clones allowed"
read -p "to be logged into this account simultaenously: " clones
while ! [[ $clones =~ $re ]]; do 
	echo "Error: Not a number"
	read -p "to be logged into this account simultaenously: " clones
done
echo ""
echo "Please choose desired control flags. List of flags:"
echo "A - Administrator (Be able to kill/quit the bot)"
echo "a - Access statistics (Things more sensitive than an average user has access to)"
echo "L - Force logout (Be able to force other users to log out of bot)"
echo "t - Transverse (Command bot to JOIN/PART channels)"
echo "s - Speak (Command bot to PRIVMSG/ACTION channels)"
echo "n - Nick (Command bot to change nick)"
echo "i - Ignore (Command bot to ignore/unignore n!u@h masks)"
echo "m - Module access (Be able to use loaded modules)"
echo "M - Module control (Load, unload, reload modules)"
echo "f - Access factoids (Be able to interact with the factoids module)"
echo "F - Modify factoids (Teach new factoids, and modify and delete existing factoids)"
echo ""
echo "Note that your desired flags should be entered all at once."
echo "(e.x. Desired flags: AaLtsnimMfF)"
echo ""
read -p "Please enter desired control flags: " flags
echo ""
echo "Creating user ${username}..."
touch "users/${username}.conf"
echo "user=\"${username}\"" >> users/${username}.conf
echo "pass=\"${passHash}\"" >> users/${username}.conf
echo "flags=\"${flags}\"" >> users/${username}.conf
echo "clones=\"${clones}\"" >> users/${username}.conf
echo "Done."
exit 0

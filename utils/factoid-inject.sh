#!/usr/bin/env bash

# MySQL Username
sqlUser="puddingbot"
# MySQL password
sqlPass="test"
# MySQL Database Name. Usually the username is fine.
sqlDBname="puddingbot"

echo "What's the full N!U@H you want the factoids added under?"
echo "(Default is: goose!goose@wash.captain-kickass.net)"
read -p "> " senderFull
if [[ -z "${senderFull}" ]]; then
	senderFull="goose!goose@wash.captain-kickass.net"
fi

echo ""
echo "Using N!U@H: ${senderFull}"
echo ""
echo "Full path to file of factoids to add?"
read -p "> " path

if ! [[ -e "${path}" ]]; then
	echo "${path} does not appear to exist!"
	exit 255
fi

echo "Adding factoid values..."
cat "${path}" | while read i; do
	factTrig="${i%% is <*}"
	factTrig="$(sed "s/'/''/g" <<<"${factTrig}")"
	factTrig="$(sed 's/\\/\\\\/g' <<<"${factTrig}")"
	factVal="${i#*>}"
	factVal="${factVal# }"
	factVal="$(sed "s/'/''/g" <<<"${factVal}")"
	factVal="$(sed 's/\\/\\\\/g' <<<"${factVal}")"
	factType="${i#*<}"
	factType="${factType%%>*}"
	factType="<${factType,,}>"
	time="$(date +%s)"
	mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDBname}; INSERT INTO factoids VALUES ('${factTrig}','${factType} ${factVal}','0','${senderFull}','${time}','${senderFull}','${time}','0','');" 
	echo "Added \"${factTrig}\" -> \"${factType} ${factVal}\""
done

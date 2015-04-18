#!/usr/bin/env bash

inArray () {
# When passing items to this to see if they're in the array or not,
# the format should be:
# inArray "${itemToBeCheck}" "${arrayToCheck[@]}"
# If it is in the array, it'll return the boolean of inArr=1.
local n=${1} h
shift
for h; do
	if [[ ${n} = "${h}" ]]; then
		inArr="1"
	else
		inArr="0"
	fi
done
}

rehash () {
rm "var/.conf"
rm "var/.api"

egrep -v "(^$|^#)" "${apiFile}" >> var/.api

sqlUser="$(egrep -m 1 "^sqlUser=\"" "${confFile}")"
sqlUser="${sqlUser#sqlUser=\"}"
sqlUser="${sqlUser%\"}"
if [[ -z "${sqlUser}" ]]; then
	sqlSupport="0"
else
	sqlPass="$(egrep -m 1 "^sqlPass=\"" "${confFile}")"
	sqlPass="${sqlPass#sqlPass=\"}"
	sqlPass="${sqlPass%\"}"
	if [[ -z "${sqlPass}" ]]; then
		sqlSupport="0"
	else
		sqlDB="$(egrep -m 1 "^sqlDBname=\"" "${confFile}")"
		sqlDB="${sqlDB#sqlDBname=\"}"
		sqlDB="${sqlDB%\"}"
		if [[ -z "${sqlDB}" ]]; then
			sqlSupport="0"
		else
			mysql --raw --silent -u ${sqlUser} -p${sqlPass} -e "USE ${sqlDB};" > /dev/null 2>&1
			if [[ "${?}" -eq "0" ]]; then
				sqlSupport="1"
			else
				sqlSupport="0"
			fi
		fi
	fi
fi

egrep -v "^#" "${confFile}" | egrep -v "^loadMod=\"" | while read i; do
	testVar="${i}"
	testVar="${testVar#*=\"}"
	testVar="${testVar%\"}"
	if [[ "${i%%=\"*}" == "logIn" ]]; then
		case "${testVar,,}" in
			yes)
			i="logIn=\"1\"";;
			no)
			i="logIn=\"0\"";;
		esac
	fi
	echo "${i}" >> var/.conf
done

echo "sqlSupport=\"${sqlSupport}\"" >> var/.conf
echo "confFile=\"${confFile}\""
echo "apiFile=\"${apiFile}\""

source var/.conf
source var/.api
}

getRandomNick () {
	readarray -t randomArr < "var/.track/${senderTarget,,}"
	randomNick="${randomArr[${RANDOM} % ${#randomArr[@]} ]] }"
	for z in "${prefixSym[@]}"; do
		randomNick="${randomNick#${z}}"
	done
	while [[ "${atkTrg,,}" == "${nick,,}" ]]; do
		randomNick="${randomArr[${RANDOM} % ${#randomArr[@]} ]] }"
		for z in "${prefixSym[@]}"; do
			randomNick="${randomNick#${z}}"
		done
	done
}

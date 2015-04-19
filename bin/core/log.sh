#!/usr/bin/env bash

logDir="${dataDir}/logs"

if ! [[ -d "${logDir}" ]]; then
	mkdir "${logDir}"
fi
if ! [[ -d "${logDir}/${networkName}" ]]; then
	mkdir "${logDir}/${networkName}"
fi

logTarget="${senderTarget}"
msgTime="$(date "+%H:%M:%S")"
msgRaw=(${msgRaw})
case "${1}" in
	--in)
	case "${msgRaw[1]^^}" in
		JOIN) 
		echo "${msgTime} -!- ${senderNick} [${senderUser}@${senderHost}] has joined ${logTarget}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		;;
		KICK)
		kickReason="${msgRaw[@]:4}"
		echo "${msgTime} -!- ${senderNick} [${senderUser}@${senderHost}] has left ${logTarget} [${partReason}]" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		;;
		NOTICE)
		re='[#|&]'
		noticeMsg="${msgRaw[@]:3}"
		if [[ "${msgRaw[2]:0:1}" =~ ${re} ]]; then
			echo "${msgTime} -!- ${senderNick}:${logTarget}- ${noticeMsg#:}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		else
			logTarget="${senderNick}"
			echo "${msgTime} -!- ${senderNick}(${senderUser}@${senderHost})- ${noticeMsg#:}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		fi
		;;
		PRIVMSG)
		re='[#|&]'
		if [[ "${msgRaw[2]:0:1}" =~ ${re} ]]; then
			readarray -t nickTypeArr < "var/.track/${logTarget,,}"
			for nickTypeTmp in "${nickTypeArr[@]}"; do
				if [[ "${nickTypeTmp}" =~ ${prefixSymReg}"${senderNick}" ]]; then
					nickType="<${nickTypeTmp}>"
					break
				elif [[ "${nickTypeTmp}" == "${senderNick}" ]]; then
					nickType="< ${nickTypeTmp}>"
					break
				fi
			done 
		else
			nickType="<${senderNick}>"
			logTarget="${senderNick}"
		fi
		if [[ "${msgRaw[3]}" == ":ACTION" ]]; then
			actMsg="${msgRaw[@]:4}"
			echo "${msgTime} * ${senderNick} ${actMsg%}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		else
			sayMsg="${msgRaw[@]:3}"
			echo "${msgTime} ${nickType} ${sayMsg#:}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		fi
		;;
		QUIT)
		quitMsg="${msgRaw[@]:2}"
		for file in "$(fgrep -l -R "${senderNick}" "var/.track")"; do
			readarray -t quitArr < "${file}"
			for tmp in "${quitArr[@]}"; do
				if [[ "${tmp}" =~ ${prefixSymReg}"${senderNick}" ]]; then
					logTarget="${logDir}/${networkName,,}/${file#var/.track/}.log"
					logTarget="${logTarget//\/\///}"
					echo "${msgTime} -!- ${senderNick} [${senderUser}@${senderHost}] has quit [${quitMsg#:}]" >> "${logTarget}"
					break
				elif [[ "${tmp}" == "${senderNick}" ]]; then
					logTarget="${logDir}/${networkName,,}/${file#var/.track/}.log"
					logTarget="${logTarget//\/\///}"
					echo "${msgTime} -!- ${senderNick} [${senderUser}@${senderHost}] has quit [${quitMsg#:}]" >> "${logTarget}"
					break
				fi
			done 
			break
		done
		;;
		MODE)
		modeChg="${msgRaw[@]:3}"
		echo "${msgTime} -!- mode/${logTarget} [${modeChg}] by ${senderNick}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		;;
		PART) 
		partReason="${msgRaw[@]:3}"
		echo "${msgTime} -!- ${senderNick} [${senderUser}@${senderHost}] has left ${logTarget} [${partReason#:}]" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		;;
		NICK)
		for file in "$(egrep -l -R "^${prefixSymReg}?${senderNick}" "var/.track")"; do
			file="${file#var/.track/}"
			echo "${msgTime} -!- ${senderNick} is now known as ${msgRaw[2]#:}" >> "${logDir}/${networkName,,}/${file,,}.log"
		done
		;;
		WALLOPS)
		;;
		TOPIC)
		topicMsg="${msgRaw[@]:3}"
		echo "${msgTime} -!- ${senderNick} has changed the topic of ${logTarget} to: ${topicMsg#:}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		;;
		INVITE)
		;;
		*)
		echo "$(date -R) [${0}] ${msgRaw[@]}" >> ${dataDir}/$(<var/bot.pid).debug
		;;
	esac
	;;
	--out)
		re='[#|&]'
		if [[ "${logTarget:0:1}" =~ ${re} ]]; then
			nickType="$(egrep "^${prefixSymReg}?${nick}" "var/.track/${logTarget,,}")"
			if [[ "${nickType:0:1}" =~ ${prefixSymReg} ]]; then
				nickType="<${nickType}>"
			else
				nickType="< ${nickType}>"
			fi
		else
			nickType="<${nick}>"
			logTarget="${senderNick}"
		fi
		outLineArr=(${outLine})
		if [[ "${outLineArr[0]}" == "ACTION" ]]; then
			actMsg="${outLineArr[@]:1}"
			echo "${msgTime} * ${nick} ${actMsg%}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		else
			echo "${msgTime} ${nickType} ${outLineArr[@]}" >> "${logDir}/${networkName,,}/${logTarget,,}.log"
		fi
	;;
	--nick)
	for file in var/.track/*; do
		file="${file#var/.track/}"
		echo "${msgTime} -!- You're now known as ${msgRaw[4]}" >> "${logDir}/${networkName,,}/${file,,}.log"
	done
	;;
	--start)
	echo "--- Log opened $(date "+%a %b %d %H:%M:%S %Y")" >> "${logDir}/${networkName,,}/${item,,}.log"
	;;
	--stop)
	echo "--- Log closed $(date "+%a %b %d %H:%M:%S %Y")" >> "${logDir}/${networkName,,}/${item,,}.log"
	;;
	--day)
	readarray -t inChan < "var/.inchan"
	for item in "${inChan[@]}"; do
		echo "--- Day changed $(date "+%a %b %d %Y")" >> "${logDir}/${networkName,,}/${item,,}.log"
	done
	;;
	--quit)
	if [[ -e "var/.inchan" ]]; then
		readarray -t inChan < "var/.inchan"
		for item in "${inChan[@]}"; do
			echo "--- Log closed $(date "+%a %b %d %H:%M:%S %Y")" >> "${logDir}/${networkName,,}/${item,,}.log"
		done
	fi
	;;
esac


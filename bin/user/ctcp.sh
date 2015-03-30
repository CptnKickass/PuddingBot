#!/usr/bin/env bash

# What kind of CTCP are they requesting?
ctcp="${msgArr[3]}"
ctcp="${ctcp#:}"
ctcp="${ctcp%}"
ctcp="${ctcp^^}"
case "${ctcp}" in
	PING)
		ms="$(date +%s)"
		if [[ -z "${msgArr[5]}" ]]; then
			echo "${ctcp} ${ms}" 
		else
			ms2=$(($(date +%s%N)/1000000))
			echo "${ctcp} ${ms} ${ms2:7:6}" 
		fi
		;;
	VERSION)
		ver="$(fgrep -m 1 "## Version " controller.sh)"
		ver="${ver#\#\# Version }"
		echo "${ctcp} PuddingBot v${ver}" 
		;;
	TIME|DATE)
		echo "${ctcp} $(date | head -n 1)" 
		;;
esac

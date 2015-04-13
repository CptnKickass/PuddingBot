#!/usr/bin/env bash

if [[ -n "${currDay}" ]]; then
	if [[ "${currDay}" -ne "$(date +%d)" ]]; then
		source ./bin/core/log.sh --day
	fi
else
	currDay="$(date +%d)"
fi

#!/usr/bin/env bash

startTime="$(egrep -m 1 "^startTime=\"" var/.status)"
startTime="${startTime#*\"}"
startTime="${startTime%\"}"
timeDiff="$(( $(date +%s) - ${startTime} ))"
days="$((timeDiff/60/60/24))"
if [[ "${days}" -eq "1" ]]; then
	days="${days} day"
else
	days="${days} days"
fi
hours="$((timeDiff/60/60%24))"
if [[ "${hours}" -eq "1" ]]; then
	hours="${hours} hour"
else
	hours="${hours} hours"
fi
minutes="$((timeDiff/60%60))"
if [[ "${minutes}" -eq "1" ]]; then
	minutes="${minutes} minute"
else
	minutes="${minutes} minutes"
fi
seconds="$((timeDiff%60))"
if [[ "${seconds}" -eq "1" ]]; then
	seconds="${seconds} second"
else
	seconds="${seconds} seconds"
fi
echo "Uptime: ${days}, ${hours}, ${minutes}, ${seconds}"

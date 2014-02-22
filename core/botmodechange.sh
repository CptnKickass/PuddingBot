source var/.conf
message="$@"
if [ "$(awk '{print $2}' <<<"$message" | egrep -c "(MODE|JOIN|PART)")" -eq "0" ]; then
	echo "[DEBUG - ${0}] $message"
	echo "$(date -R) [${0}] ${message}" >> ${dataDir}/$(<var/bot.pid).debug
fi

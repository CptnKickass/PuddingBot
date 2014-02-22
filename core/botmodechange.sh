source var/.conf
message="$@"
if [ "$(awk '{print $2}' <<<"$message" | egrep -c "(MODE|JOIN|PART)")" -eq "0" ]; then
	echo "[DEBUG-botmodechange.sh] $message"
	echo "$(date) | Received unknown message level 2: ${message}" >> ${dataDir}/$(<var/bot.pid).debug
fi

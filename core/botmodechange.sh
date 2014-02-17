			if [ "$(echo "$message" | awk '{print $2}' | egrep -c "(MODE|JOIN|PART)")" -eq "0" ]; then
				echo "$(date) | Received unknown message level 2: ${message}" >> ${dataDir}/$$.debug
			fi

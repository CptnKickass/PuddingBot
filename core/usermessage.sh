case "$com" in
	join)
	if [ -z "$(echo "$msg" | awk '{print $5}')" ]; then
		echo "This command requires a parameter"
	elif [ "$(echo "$msg" | awk '{print $5}' | egrep -c "^(#|&)")" -eq "0" ]; then
		echo "$(echo "$msg" | awk '{print $5}') does not appear to be a valid channel"
	else
		echo "JOIN $(echo "$msg" | awk '{print $5}')"
		echo "Joined $(echo "$msg" | awk '{print $5}')"
	fi
	;;
esac

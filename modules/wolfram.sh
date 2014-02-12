# WolframAlpha API Key
wolfApi=""
wolfram)
	# Color character used to start a category: [1;36m
	# Color character used to end a category: [0m
	if [ -z "$(echo "$message" | awk '{print $5}')" ]; then
		echo "PRIVMSG $senderTarget :This command requires a parameter" >> $output
	else
		unset wolfArr
		wolfQ="$(read -r one two three four rest <<<"$message"; echo "$rest")"
		# properly encode query
		wolfQ="$(echo "${wolfQ}" | sed 's/+/%2B/g' | tr '\ ' '\+')"
		# fetch and parse result
		result=$(curl -s "http://api.wolframalpha.com/v2/query?input=${wolfQ}&appid=${wolfApi}&format=plaintext")
		echo "PRIVMSG $senderTarget :Wolfram Alpha Results:" >> $output
		echo -e ${result} | tr '\n' '\t' | sed -e 's/<plaintext>/\'$'\n<plaintext>/g' | grep -oE "<plaintext>.*</plaintext>|<pod title=.[^\']*" | sed 's!<plaintext>!!g; s!</plaintext>!!g;  s!<pod title=.*!\\\x1b[1;36m&\\\x1b[0m!g; s!<pod title=.!!g; s!\&amp;!\&!' | tr '\t' '\n' | sed  '/^$/d; s/\ \ */\ /g' | while read line; do
			if [ "$(echo "$line" | egrep -c "$(echo -e "\e\[1;36m")")" -eq "1" ]; then
				# It's a category
				echo "PRIVMSG $senderTarget :${wolfArr[@]}" >> $output
				unset wolfArr
				line="$(echo "$line" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")"
				echo "PRIVMSG $senderTarget :${line}" >> $output
				sleep 1
			else
				# It's an answer
				wolfArr+=("$line")
			fi
		done
		echo "PRIVMSG $senderTarget :${wolfArr[@]}" >> $output
		unset wolfArr
	fi
	;;

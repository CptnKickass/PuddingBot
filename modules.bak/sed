
						elif [ "$isSed" -eq "1" ]; then
							sedCom="$(echo "$message" | egrep -o -i "s\/.*\/.*\/(i|g|ig)?")"
							sedItem="${sedCom#s/}"
							sedItem="${sedItem%/*/*}"
							prevLine="$(fgrep "PRIVMSG" "${input}" | fgrep "${sedItem}" | tail -n 2 | head -n 1)"
							prevSend="$(echo "$prevLine" | awk '{print $1}' | sed "s/!.*//" | sed "s/^://")"
							line="$(read -r one two three rest <<<"${prevLine}"; echo "$rest" | sed "s/^://")"
							if [ -n "$line" ]; then
								lineFixed="$(echo "$line" | sed "${sedCom}")"
								echo "PRIVMSG $senderTarget :[FTFY] <${prevSend}> $lineFixed" >> $output
							fi


			isFox="$(echo "$message" | fgrep -c -i "what does the fox say?")"
			if [ "$isFox" -eq "1" ]; then
				if [ -z "$foxResponseNum" ]; then
					foxResponseNum="1"
				elif [ "$foxResponseNum" -eq "14" ]; then
					foxResponseNum="1"
				fi
				case $foxResponseNum in
					1) foxResponse="Ring-ding-ding-ding-dingeringeding!";;
					2) foxResponse="Gering-ding-ding-ding-dingeringeding!";;
					3) foxResponse="Wa-pa-pa-pa-pa-pa-pow!";;
					4) foxResponse="Hatee-hatee-hatee-ho!";;
					5) foxResponse="Joff-tchoff-tchoffo-tchoffo-tchoff!";;
					6) foxResponse="Tchoff-tchoff-tchoffo-tchoffo-tchoff!";;
					7) foxResponse="Jacha-chacha-chacha-chow!";;
					8) foxResponse="Chacha-chacha-chacha-chow!";;
					9) foxResponse="Fraka-kaka-kaka-kaka-kow!";;
					10) foxResponse="A-hee-ahee ha-hee!";;
					11) foxResponse="Wa-wa-way-do Wub-wid-bid-dum-way-do Wa-wa-way-do!";;
					12) foxResponse="Bay-budabud-dum-bam!";;
					13) foxResponse="Abay-ba-da bum-bum bay-do!";;
				esac
				foxResponseNum="$(( $foxResponseNum + 1 ))"
				echo "PRIVMSG $senderTarget :${foxResponse}" >> $output
			fi

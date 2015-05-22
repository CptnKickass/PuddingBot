#!/usr/bin/env bash

if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl" "w3m")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in "${deps[@]}"; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
	fi
	apiFail="0"
	apis=("youTubeApiKey" "imgurApi" "pbApiKey")
	if [[ "${#apis[@]}" -ne "0" ]]; then
		if [[ -e "api.conf" ]]; then
			for i in "${apis[@]}"; do
				val="$(egrep "^${i}" "api.conf")"
				val="${val#${i}=\"}"
				val="${val%\"}"
				if [[ -z "${val}" ]]; then
					echo -e "Missing api key \"${red}${i}${reset}\"! Exiting."
					apiFail="1"
				fi
			done
		else
			path="$(pwd)"
			path="${path##*/}"
			path="./${path}/${0##*/}"
			echo "Unable to locate \"api.conf\"!"
			echo "(Are you running the dependency check from the main directory?)"
			echo "(ex: ${path} --dep-check)"
			exit 255
		fi
	fi
	if [[ "${depFail}" -eq "0" ]] && [[ "${apiFail}" -eq "0" ]]; then
		echo "ok"
		exit 0
	else
		echo "Dependency check failed. See above errors."
		exit 255
	fi
fi

if ! [[ -e "var/.conf" ]]; then
	nick="Null"
fi
if [[ "${#msgArr[@]}" -eq "0" ]]; then
	mapfile -t msgArr < list.txt
	source var/.conf
	source var/.api
fi

modHook="Format"
modForm=("^:.+!.+@.+ PRIVMSG (&|#).* :.*?http(s?):\/\/[^ \"\(\)\<\>]*")
modFormCase="Yes"
modHelp="Gets a URL's <title> and some other useful info"
modFlag="m"

getTitle () {
	titleStart="$(fgrep -m 1 -n "<title" <<<"${pageSrc}" | awk '{print $1}')"
	titleStart="${titleStart%%:*}"
	titleEnd="$(fgrep -m 1 -n "</title>" <<<"${pageSrc}" | awk '{print $1}')"
	titleEnd="${titleEnd%%:*}"
	if [[ "${titleStart}" -eq "${titleEnd}" ]]; then
		pageTitle="$(curl -A "${nick}" -m 5 -k -s -L "${url}" | egrep -m 1 "<title.*</title>")"
	else
		tmp="$(mktemp)"
		tmp2="$(mktemp)"
		echo "${pageSrc}" > "${tmp}"
		head -n ${titleEnd} "${tmp}" | tail -n $(( ${titleStart} + 1 )) > "${tmp2}"
		rm "${tmp}"
		pageTitle="$(tr '\n' ' ' < "${tmp2}")"
		rm "${tmp2}"
	fi
	pageTitle="${pageTitle%%</title>*}"
	pageTitle="${pageTitle##*>}"
	pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
	if [[ -z "${pageTitle}" ]]; then
		titleStart="$(fgrep -m 1 -n "<title" <<<"${pageSrc}" | awk '{print $1}')"
		titleStart="${titleStart%%:*}"
		titleEnd="$(fgrep -m 1 -n "</title>" <<<"${pageSrc}" | awk '{print $1}')"
		titleEnd="${titleEnd%%:*}"
		if [[ "${titleStart}" -eq "${titleEnd}" ]]; then
			pageTitle="$(curl -A "${nick}" -m 5 -k -s -L "${url}" | egrep -m 1 "<title.*</title>")"
		else
			tmp="$(mktemp)"
			tmp2="$(mktemp)"
			echo "${pageSrc}" > "${tmp}"
			head -n ${titleEnd} "${tmp}" | tail -n $(( ${titleStart} + 1 )) > "${tmp2}"
			rm "${tmp}"
			pageTitle="$(tr '\n' ' ' < "${tmp2}")"
			rm "${tmp2}"
		fi
		pageTitle="${pageTitle%%</title>*}"
		pageTitle="${pageTitle##*>}"
		pageTitle="$(sed -e 's/^[ \t]*//' <<<"${pageTitle}" | w3m -dump -T text/html | tr '\n' ' ')"
	fi
	if [[ -z "${pageTitle}" ]]; then
		pageTitle="[Unable to obtain title] (${url})"
	fi
}

youtube () {
	if [[ "${url#*://}" =~ "youtu.be"* ]]; then
		vidId="${url#*youtu.be/}"
		vidId="${vidId:0:11}"
	elif [[ "${url,,}" == *"watch?v="* ]]; then
		vidId="${url#*watch?v=}"
		vidId="${vidId:0:11}"
	else
		unset vidId
	fi
	apiUrl="https://www.googleapis.com/youtube/v3/videos?id=${vidId}&key=${youTubeApiKey}&part=snippet,contentDetails"
	vidInfo="$(curl -A "${nick}" -m 5 -k -s -L "${apiUrl}")"
	vidTitle="$(fgrep -m 1 "\"title\": \"" <<<"${vidInfo}")"
	vidTitle="${vidTitle%\",*}"
	vidTitle="${vidTitle#*\"title\": \"}"
	duration="$(fgrep "\"duration\": \"PT" <<<"${vidInfo}")"
	duration="${duration#*PT}"
	duration="${duration%\",*}"
	duration="${duration,,}"
	if [[ -z "${vidId}" ]]; then
		getTitle;
		pageTitle="${pageTitle}"
	elif [[ -z "${vidTitle}" ]]; then
		getTitle;
	else
		pageTitle="${vidTitle} [${duration}]"
	fi
	pageTitle="${pageTitle//\\\"/\"}"
	echo "[YouTube] ${pageTitle}"
}

newegg () {
	pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
	getTitle;
	re="^http(s)?://(www\.)?newegg\.com/Product/"
	if [[ "${url,,}" =~ ${re,,} ]]; then
		itemPrice="$(fgrep -m 1 "product_sale_price" <<<"${pageSrc}")"
		itemPrice="${itemPrice#*\'}"
		itemPrice="${itemPrice%*\'*}"
		if [[ "$(fgrep -c "Discontinued" <<<"${itemPrice}")" -eq "1" ]]; then
			pageTitle="${pageTitle} [Item Discontinued]"
		elif [[ -n "${itemPrice}" ]]; then
			pageTitle="${pageTitle} [Price: \$${itemPrice}]"
		fi
	fi
	echo "[NewEgg] ${pageTitle}"
}

amazon () {
	pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
	getTitle;
	re="http(s)?://(www\.|smile\.)?ama?zo?n\.(com|co\.uk|com\.au|de|fr|ca|cn|es|it)/.*/(?:exec/obidos/ASIN/|o/|gp/product/|(?:(?:[^\"'/]*)/)?dp/|)(B[A-Z0-9]{9})"
	if egrep -q "${re}" <<< "${url}"; then
		if fgrep -qi "Currently unavailable" <<<"${pageSrc}"; then
			pageTitle="${pageTitle} [Item not currently available]"
		else
			itemPrice=($(egrep -o -m 1 "\\\$([0-9]|,)+\.[0-9][0-9]" <<<"${pageSrc}"))
			if [[ "${#itemPrice[@]}" -ne "0" ]]; then
				pageTitle="${pageTitle} [Price: ${itemPrice[0]}]"
			fi
		fi
	fi
	echo "[Amazon] ${pageTitle}"
}

twitter () {
	re="http(s)?://twitter\.com/[[:alnum:]]+/status/[[:digit:]]+"
	if [[ "${url,,}" =~ ${re,,} ]]; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		pageTitle="$(fgrep "<meta  property=\"og:title\"" <<<"${pageSrc}")"
		pageTitle="${pageTitle#*content=\"}"
		pageTitle="${pageTitle%\">*}"
		pageTitle="${pageTitle% on Twitter}"
		twitterUser="${url#*twitter.com/}"
		twitterUser="${twitterUser%%/*}"
		pageDesc="$(fgrep "<meta  property=\"og:description\"" <<<"${pageSrc}")"
		pageDesc="${pageDesc#*content=\"}"
		pageDesc="${pageDesc%\">*}"
		if fgrep -q "http://t.co" <<<"${pageSrc}"; then
			short="$(fgrep -m 1 "<title" <<<"${pageSrc}")"
			short="${short#*http://t.co}"
			short="http://t.co${short%%&quot;*}"
			pageTitle="${pageTitle} (@${twitterUser}) ${short} - ${pageDesc}"
		else
			pageTitle="${pageTitle} (@${twitterUser}) - ${pageDesc}"
		fi
		pageTitle="$(w3m -dump -T text/html <<<"${pageTitle}" | tr '\n' ' ')"
	else
		getTitle;
	fi
	echo "[Twitter] ${pageTitle}"
}

speedtest() {
	unset id
	re="http(s)?://(www\.|beta\.)?speedtest\.net/result/[[:digit:]]+\.png"
	if [[ "${url,,}" =~ ${re,,} ]]; then
		id="${url#*/result/}"
		id="${id%.png}"
	fi
	re="http(s)?://(www\.)?speedtest\.net/my-result/[[:digit:]]"
	if [[ "${url,,}" =~ ${re,,} ]]; then
		id="${url#*/my-result/}"
	fi
	re="http(s)?://beta\.speedtest\.net/(my-)?result/[[:digit:]]"
	if [[ "${url,,}" =~ ${re,,} ]]; then
		id="${url#*/result/}"
	fi
	if [[ -n "${id}" ]]; then
		re="http(s)?://beta\.?speedtest\.net/(my-)?result/[[:digit:]]"
		if [[ "${url,,}" =~ ${re,,} ]]; then
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "http://beta.speedtest.net/result/${id}")"
		else
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "http://www.speedtest.net/my-result/${id}")"
		fi
		dSpeed="$(fgrep -A 2 "<div class=\"share-speed share-download\">" <<<"${pageSrc}" | tail -n 1)"
		dSpeed="${dSpeed#*<p>}"
		dSpeed="${dSpeed%%<span>*}"
		dSpeed="${dSpeed} Mb/s"
		uSpeed="$(fgrep -A 2 "<div class=\"share-speed share-upload\">" <<<"${pageSrc}" | tail -n 1)"
		uSpeed="${uSpeed#*<p>}"
		uSpeed="${uSpeed%%<span>*}"
		uSpeed="${uSpeed} Mb/s"
		ping="$(fgrep -A 2 "<div class=\"share-data share-ping\">" <<<"${pageSrc}" | tail -n 1)"
		ping="${ping#*<p>}"
		ping="${ping%%<span>*}"
		ping="${ping}"
		ispRate="$(fgrep -A 2 "<div class=\"share-data share-isp\">" <<<"${pageSrc}" | tail -n 1)"
		ispRate="${ispRate#*>}"
		ispRate="${ispRate%%</div>*}"
		ispRate="${ispRate}"
		isp="$(fgrep -A 3 "<div class=\"share-data share-isp\">" <<<"${pageSrc}" | tail -n 1)"
		isp="${isp#*<p>}"
		isp="${isp%%</p>*}"
		isp="${isp}"
		loc="$(fgrep -A 2 "<div class=\"share-data share-server\">" <<<"${pageSrc}" | tail -n 1)"
		loc="${loc#*<p>}"
		loc="${loc%%</p>*}"
		loc="${loc}"
		pageTitle="${isp} (${ispRate}) [${loc}] | Ping: ${ping} ms |  Download Speed: ${dSpeed} | Upload Speed: ${uSpeed}"
	else
		getTitle;
	fi
	echo "[SpeedTest] ${pageTitle}"
}

steam () {
	unset id
	re="https?://store.steampowered.com/app/([0-9]+)"
	re2="https?://steamcommunity\.com/(id|profiles)/[[:alnum:]]+"
	if [[ "${url,,}" =~ ${re} ]]; then
		id="${url#*/app/}"
		id="${id%%/*}"
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "http://store.steampowered.com/api/appdetails/?appids=${id}&cc=US&l=english&v=1")"
		success="${pageSrc#*\"success\":}"
		success="${success%%,*}"
		if [[ "${success,,}" == "true" ]]; then
			appName="${pageSrc#*\"name\":\"}"
			appName="${appName%%\"*}"
			appAbout="${pageSrc#*\"about_the_game\":\"}"
			appAbout="${appAbout%%.*}."
			appAbout="${appAbout//\\r<br>\\r<br>/ - }"
			appFree="${pageSrc#*\"is_free\":}"
			appFree="${appFree%%,*}"
			if [[ "${appFree,,}" == "true" ]]; then
				appCost="[Free]"
			elif [[ "${appFree,,}" == "false" ]]; then
				appPrice="${pageSrc#*\"price_overview\":\{}"
				appPrice="${appPrice%%\}*}"
				appDisc="${appPrice#*\"discount_percent\":}"
				appCost="${appPrice#*final\":}"
				appCost="${appCost%%,\"*}"
				if [[ "${appDisc}" -eq "0" ]]; then
					appCost="\$${appCost%??}.${appCost#${appCost%??}}"
				else
					appCost="\$${appCost%??}.${appCost#${appCost%??}} [${appDisc}% off]"
				fi
			else
				appCost="You should never get this error message! [Debug 5]"
			fi
			pageTitle="${appName} | ${appCost} | ${appAbout}"
			pageTitle="${pageTitle//\\r/}"
			pageTitle="$(sed -E "s/\\\u[0-9]{4}//g" <<<"${pageTitle}")"
			pageTitle="$(sed -E "s/<[^>]*>//g" <<<"${pageTitle}")"
		elif [[ "${success,,}" == "false" ]]; then
			getTitle;
		else
			pageTitle="You should never get this message. What did you do? [Debug 6]"
		fi
	elif [[ "${url,,}" =~ ${re2} ]]; then
		re3="https?://steamcommunity\.com/id/[[:alnum:]]+"
		re4="https?://steamcommunity\.com/profiles/[[:digit:]]+"
		if [[ "${url,,}" =~ ${re3} ]]; then
			id="${url#*/id/}"
			id="${id%%/*}"
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "http://steamcommunity.com/id/${id}")"
			if fgrep -q "\"steamid\":" <<<"${pageSrc}"; then
				id="$(fgrep -m 1 "\"steamid\":" <<<"${pageSrc}")"
				id="${id#*\"steamid\":}"
				id="${id%%,*}"
				id="${id#\"}"
				id="${id%\"}"
				if [[ "${id,,}" == "null" ]]; then
					unset id
					getTitle;
				fi
			fi
		elif [[ "${url,,}" =~ ${re4} ]]; then
			id="${url#*/profiles/}"
			id="${id%%/*}"
		else
			unset id
			getTitle;
		fi
		if [[ -n "${id}" ]]; then
			if [[ "${id,,}" == "null" ]]; then
				getTitle;
			else
				steamApi="698036DE5441E9F9368FBE87B742F1DF"
				summary="$(curl -A "${nick}" -m 5 -k -s -L "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=${steamApi}&steamids=${id}")"
				friends="$(curl -A "${nick}" -m 5 -k -s -L "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key=${steamApi}&steamid=${id}")"
				games="$(curl -A "${nick}" -m 5 -k -s -L "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=${steamApi}&steamid=${id}")"
				recent="$(curl -A "${nick}" -m 5 -k -s -L "http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=${steamApi}&steamid=${id}")"
				visibility="$(fgrep -m 1 "\"communityvisibilitystate\":" <<<"${summary}")"
				visibility="${visibility#*\"communityvisibilitystate\": }"
				visibility="${visibility%,*}"
				if [[ "${visibility,,}" -eq "3" ]]; then
					profName="$(fgrep -m 1 "\"personaname\":" <<<"${summary}")"
					profName="${profName#*\"personaname\": }"
					profName="${profName%,*}"
					profName="${profName#\"}"
					profName="${profName%\"}"
					if [[ "${profName,,}" == "null" ]]; then
						profName="[No name set]"
					fi
					inGame="$(fgrep -m 1 "\"gameextrainfo\":" <<<"${summary}")"
					inGame="${inGame#*\"gameextrainfo\": }"
					inGame="${inGame%,*}"
					inGame="${inGame#\"}"
					inGame="${inGame%\"}"
					created="$(fgrep -m 1 "\"timecreated\":" <<<"${summary}")"
					created="${created#*\"timecreated\": }"
					created="${created%,*}"
					created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
					lastOnline="$(fgrep -m 1 "\"lastlogoff\":" <<<"${summary}")"
					lastOnline="${lastOnline#*\"lastlogoff\": }"
					lastOnline="${lastOnline%,*}"
					lastOnline="$(date -d @${lastOnline} "+%a, %b %d, %Y @ %H:%M:%S")"
					onlineStatus="$(fgrep -m 1 "\"personastate\":" <<<"${summary}")"
					onlineStatus="${onlineStatus#*\"personastate\": }"
					onlineStatus="${onlineStatus%,*}"
					case "${onlineStatus}" in
						0) onlineStatus="Offline (Last online ${lastOnline})";;
						1) onlineStatus="Online";;
						2) onlineStatus="Busy";;
						3) onlineStatus="Away";;
						4) onlineStatus="Snooze";;
						5) onlineStatus="Looking to trade";;
						6) onlineStatus="Looking to play";;
						*) onlineStatus="Unknown";;
					esac
					if [[ -n "${inGame}" ]]; then
						onlineStatus="${onlineStatus} (In game: ${inGame})"
					fi
					friends="$(fgrep -c "\"relationship\": \"friend\"" <<<"${friends}")"
					if [[ "${friends}" -gt "999" ]]; then
						friends="$(printf "%'d" ${friends})"
					fi
					games="$(fgrep -c "\"appid\": " <<<"${games}")"
					if [[ "${games}" -gt "999" ]]; then
						games="$(printf "%'d" ${games})"
					fi
					recentCount="$(fgrep -m 1 "\"total_count\": " <<<"${recent}")"
					recentCount="${recentCount#*\"total_count\": }"
					recentCount="${recentCount%,*}"
					recentCount="${recentCount#\"}"
					recentCount="${recentCount%\"}"
					if [[ "${recentCount}" -gt "0" ]]; then
						recentName="$(fgrep -m 1 "\"name\": " <<<"${recent}")"
						recentName="${recentName#*\"name\": }"
						recentName="${recentName%,*}"
						recentName="${recentName#\"}"
						recentName="${recentName%\"}"
						recent2weeks="$(fgrep -m 1 "\"playtime_2weeks\": " <<<"${recent}")"
						recent2weeks="${recent2weeks#*\"playtime_2weeks\": }"
						recent2weeks="${recent2weeks%,*}"
						recent2weeks="${recent2weeks#\"}"
						recent2weeks="${recent2weeks%\"}"
						recent2weeks="$(( ${recent2weeks} * 60 ))"
						recentEver="$(fgrep -m 1 "\"playtime_forever\": " <<<"${recent}")"
						recentEver="${recentEver#*\"playtime_forever\": }"
						recentEver="${recentEver%,*}"
						recentEver="${recentEver#\"}"
						recentEver="${recentEver%\"}"
						recentEver="$(( ${recentEver} * 60 ))"
						days="$((recent2weeks/60/60/24))"
						if [[ "${days}" -eq "1" ]]; then
							days="${days} day"
						else
							days="${days} days"
						fi
						hours="$((recent2weeks/60/60%24))"
						if [[ "${hours}" -eq "1" ]]; then
							hours="${hours} hour"
						else
							hours="${hours} hours"
						fi
						minutes="$((recent2weeks/60%60))"
						if [[ "${minutes}" -eq "1" ]]; then
							minutes="${minutes} minute"
						else
							minutes="${minutes} minutes"
						fi
						seconds="$((recent2weeks%60))"
						if [[ "${seconds}" -eq "1" ]]; then
							seconds="${seconds} second"
						else
							seconds="${seconds} seconds"
						fi
						unset recent2weeks
						if [[ "${days%% *}" -gt "0" ]]; then
							recent2weeks="${days}"
						fi
						if [[ "${hours%% *}" -gt "0" ]]; then
							recent2weeks="${recent2weeks}, ${hours}"
						fi
						if [[ "${minutes%% *}" -gt "0" ]]; then
							recent2weeks="${recent2weeks}, ${minutes}"
						fi
						if [[ "${seconds%% *}" -gt "0" ]]; then
							recent2weeks="${recent2weeks}, ${seconds}"
						fi
						recent2weeks="${recent2weeks#, }"
						days="$((recentEver/60/60/24))"
						if [[ "${days}" -eq "1" ]]; then
							days="${days} day"
						else
							days="${days} days"
						fi
						hours="$((recentEver/60/60%24))"
						if [[ "${hours}" -eq "1" ]]; then
							hours="${hours} hour"
						else
							hours="${hours} hours"
						fi
						minutes="$((recentEver/60%60))"
						if [[ "${minutes}" -eq "1" ]]; then
							minutes="${minutes} minute"
						else
							minutes="${minutes} minutes"
						fi
						seconds="$((recentEver%60))"
						if [[ "${seconds}" -eq "1" ]]; then
							seconds="${seconds} second"
						else
							seconds="${seconds} seconds"
						fi
						unset recentEver
						if [[ "${days%% *}" -gt "0" ]]; then
							recentEver="${days}"
						fi
						if [[ "${hours%% *}" -gt "0" ]]; then
							recentEver="${recentEver}, ${hours}"
						fi
						if [[ "${minutes%% *}" -gt "0" ]]; then
							recentEver="${recentEver}, ${minutes}"
						fi
						if [[ "${seconds%% *}" -gt "0" ]]; then
							recentEver="${recentEver}, ${seconds}"
						fi
						recentEver="${recentEver#, }"
						pageTitle="${profName} [${onlineStatus}] | Created ${created} | ${friends} Friends | ${games} Games | Recently Played: ${recentName} (${recent2weeks} in the last 2 weeks :: ${recentEver} on record)"
					else
						pageTitle="${profName} [${onlineStatus}] | Created ${created} | ${friends} Friends | ${games} Games"
					fi
				else
					url="http://steamcommunity.com/id/${id}"
					getTitle;
				fi
			fi
		else
			getTitle;
		fi
	else
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		getTitle;
	fi
	echo "[Steam] ${pageTitle}"
}

wikipedia () {
	unset id
	re="https?://(en|www)\.wikipedia\.org/wiki/([[:alnum:]]|[[:punct:]])+"
	if [[ "${url,,}" =~ ${re} ]]; then
		id="${url#*/wiki/}"
	fi
	if [[ -n "${id}" ]]; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro=&explaintext=&titles=${id}")"
		title="${pageSrc#*\"title\":\"}"
		title="${title%%\",\"*}"
		if fgrep -q "\"extract\":\"\"" <<<"${pageSrc}"; then
			pageTitle="${title}"
		else
			desc="${pageSrc#*\"extract\":\"}"
			desc="${desc%%.*}."
			pageTitle="${title} - ${desc}"
		fi
	else
		getTitle;
	fi
	echo "[Wikipedia] ${pageTitle}"
}

reddit () {
	type="0"
	re="https?://(www\.)?reddit\.com/r/[[:alnum:]]+/comments/.*\?context=[[:digit:]]+.*"
	re2="https?://(www\.)?reddit\.com/r/[[:alnum:]]+/comments/[[:alnum:]]+"
	re3="https?://(www\.)?reddit\.com/r/[[:alnum:]]+"
	re4="https?://(www\.)?reddit\.com/(u|user)/[[:alnum:]]+"
	if [[ "${url,,}" =~ ${re} ]]; then
		id="${url%%?context=*}"
		type="1"
	elif [[ "${url,,}" =~ ${re2} ]]; then
		id="${url}"
		type="1"
	elif [[ "${url,,}" =~ ${re3} ]]; then
		id="${url}"
		type="2"
	elif [[ "${url,,}" =~ ${re4} ]]; then
		id="${url#*reddit.com/user/}"
		id="${id#*reddit.com/u/}"
		id="${id%%/*}"
		id="https://www.reddit.com/user/${id}/about.json"
		type="3"
	fi
	if [[ "${type}" -eq "1" ]]; then
		if fgrep -q "\"error\"" <<<"${pageSrc}"; then
			getTitle;
		else
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${id}.json")"
			pageSrc="{${pageSrc#*\{}"
			pageSrc="${pageSrc%%\}\}*}}"
			author="${pageSrc#*\"author\": \"}"
			author="${author%%\"*}"
			if ! [[ "${author,,}" == "[deleted]" ]]; then
				author="/u/${author}"
			fi
			nsfw="${pageSrc#*\"over_18\": }"
			nsfw="${nsfw%%,*}"
			subreddit="${pageSrc#*\"subreddit\": \"}"
			subreddit="${subreddit%%\"*}"
			title="${pageSrc#*\"title\": \"}"
			title="${title%%\"*}"
			title="${title//\\\"/\"}"
			id="${pageSrc#*\"id\": \"}"
			id="${id%%\"*}"
			link="${pageSrc#*\"url\": \"}"
			link="${link%%\"*}"
			self="${pageSrc#*\"is_self\": }"
			self="${self%%,*}"
			comments="${pageSrc#*\"num_comments\": }"
			comments="${comments%%,*}"
			if [[ "${comments}" -eq "1" ]]; then
				comments="${comments} comment"
			elif [[ "${comments}" -gt "1" ]] && [[ "${comments}" -le "999" ]]; then
				comments="${comments} comments"
			elif [[ "${comments}" -gt "999" ]]; then
				comments="$(printf "%'d" ${comments}) comments"
			else
				comments="You should never get this message! [Debug 1]"
			fi
			if [[ "${self,,}" == "true" ]]; then
				link="(Self Post) ${comments} :  http://redd.it/${id}"
			elif [[ "${self,,}" == "false" ]]; then
				link="${link} | ${comments} : http://redd.it/${id}"
			else
				echo "You should never get this message! [Debug 2]"
			fi
			ratio="${pageSrc#*\"upvote_ratio\": }"
			ratio="${ratio%%,*}"
			ratio="${ratio#0.}"
			if [[ "${ratio}" == "1.0" ]]; then
				ratio="100"
			elif [[ "${ratio}" -lt "10" ]]; then
				ratio="${ratio}0"
			fi
			score="${pageSrc#*\"score\": }"
			score="${score%%,*}"
			if [[ "${score}" -gt "999" ]]; then
				score="$(printf "%'d" ${score})"
			fi
			created="${pageSrc#*\"created\": }"
			created="${created%%,*}"
			created="${created%.*}"
			created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
			if [[ "${nsfw,,}" == "true" ]]; then
				pageTitle="[NSFW] (${author} in /r/${subreddit}) ${title} | ${link} | ${score} Points : ${ratio}% Upvoted | Posted ${created}"
			else
				pageTitle="(${author} in /r/${subreddit}) ${title} | ${link} | ${score} Points : ${ratio}% Upvoted | Posted ${created}"
			fi
		fi
	elif [[ "${type}" -eq "2" ]]; then
		# Place holder for subreddit main pages
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${id}/about.json")"
		if fgrep -q "\"error\"" <<<"${pageSrc}"; then
			getTitle;
		else
			kind="${pageSrc#*\"kind\": \"}"
			kind="${kind%%\"*}"
			if [[ "${kind,,}" == "t5" ]]; then
				subName="${pageSrc#*\"display_name\": \"}"
				subName="${subName%%\"*}"
				tagLine="${pageSrc#*\"title\": \"}"
				tagLine="${tagLine%%\"*}"
				subs="${pageSrc#*\"subscribers\": }"
				subs="${subs%%,*}"
				if [[ "${subs}" -gt "999" ]]; then
					subs="$(printf "%'d" ${subs})"
				fi
				active="${pageSrc#*\"accounts_active\": }"
				active="${active%%,*}"
				if [[ "${active}" -gt "999" ]]; then
					active="$(printf "%'d" ${active})"
				fi
				created="${pageSrc#*\"created\": }"
				created="${created%%,*}"
				created="${created%.*}"
				created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
				pageTitle="/r/${subName} | ${tagLine% } | Created ${created} | ${subs} Subscribers | ${active} Users currently viewing"
			elif [[ "${kind,,}" == "listing" ]]; then
				pageTitle="(/r/${id##*/}) No such subreddit exists"
			else
				pageTitle="Error: (/r/${id##*/}) No such subreddit exists"
			fi
		fi
	elif [[ "${type}" -eq "3" ]]; then
		# Place holder for username pages
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${id}")"
		if fgrep -q "\"error\"" <<<"${pageSrc}"; then
			getTitle;
		else
			name="${pageSrc#*\"name\": \"}"
			name="${name%%\"*}"
			created="${pageSrc#*\"created\": }"
			created="${created%%,*}"
			created="${created%.*}"
			created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
			linkKarma="${pageSrc#*\"link_karma\": }"
			linkKarma="${linkKarma%%,*}"
			if [[ "${linkKarma}" -gt "999" ]]; then
				linkKarma="$(printf "%'d" ${linkKarma})"
			fi
			comKarma="${pageSrc#*\"comment_karma\": }"
			comKarma="${comKarma%%,*}"
			if [[ "${comKarma}" -gt "999" ]]; then
				comKarma="$(printf "%'d" ${comKarma})"
			fi
			gold="${pageSrc#*\"is_gold\": }"
			gold="${gold%%,*}"
			mod="${pageSrc#*\"is_mod\": }"
			mod="${mod%%,*}"
			verified="${pageSrc#*\"has_verified_email\": }"
			verified="${verified%%,*}"
			pageTitle="/u/${name} | Created ${created} | ${linkKarma} Link Karma | ${comKarma} Comment Karma"
			if [[ "${gold,,}" == "true" ]]; then
				pageTitle="${pageTitle} | Has Reddit Gold"
			fi
			if [[ "${verified,,}" == "true" ]]; then
				pageTitle="${pageTitle} | Verified E-Mail"
			fi
			if [[ "${mod,,}" == "true" ]]; then
				pageTitle="${pageTitle} | Is a moderator"
			fi
		fi
	else
		getTitle;
	fi
	echo "[Reddit] ${pageTitle}"
}

imgur () {
	unset id
	re="https?://imgur.com/r/[[:alnum:]]+"
	re2="https?://(i\.)?imgur.com/(a|gallery/)?[[:alnum:]]+"
	if [[ "${url,,}" =~ ${re} ]]; then
		getTitle;
		echo "[Imgur] ${pageTitle}"
	elif [[ "${url,,}" =~ ${re2} ]]; then
		# It could be in the gallery
		id="${url#*imgur.com/a/}"
		id="${url#*imgur.com/}"
		id="${id#*gallery/}"
		id="${id%%#*}"
		id="${id%%/*}"
		id="${id%%.*}"
		id="${id//,/ }"
		idArr=(${id})
	else
		getTitle;
		echo "[Imgur] ${pageTitle}"
	fi
	if [[ "${#id[@]}" -ne "0" ]]; then
		for id in "${idArr[@]}"; do
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L -H "Authorization: Client-ID ${imgurApi}" "https://api.imgur.com/3/gallery/image/${id}")"
			success="${pageSrc#*\"success\":}"
			success="${success%%,*}"
			if [[ "${success,,}" == "true" ]]; then
				# It's a gallery image
				nsfw="${pageSrc#*\"nsfw\":}"
				nsfw="${nsfw%%,*}"
				title="${pageSrc#*\"title\":\"}"
				title="${title%%\",\"*}"
				title="${title//\\\"/\"}"
				created="${pageSrc#*\"datetime\":}"
				created="${created%%,*}"
				created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
				format="${pageSrc#*\"type\":\"}"
				format="${format%%\",*}"
				format="${format//\\\///}"
				account="${pageSrc#*\"account_url\":}"
				account="${account%%,*}"
				account="${account#\"}"
				account="${account%\"}"
				if [[ "${account,,}" == "null" ]]; then
					account="[Anonymous]"
				fi
				comments="${pageSrc#*\"comment_count\":}"
				comments="${comments%%,*}" 
				if [[ "${comments}" -eq "1" ]]; then
					comments="${comments} comment"
				elif [[ "${comments}" -gt "1" ]] && [[ "${comments}" -lt "1000" ]]; then
					comments="${comments} comments"
				elif [[ "${comments}" -gt "999" ]]; then
					comments="$(printf "%'d" ${comments}) comments"
				else
					comments="You should never get this message! [Debug 3]"
				fi
				score="${pageSrc#*\"score\":}"
				score="${score%%,*}"
				if [[ "${score}" -gt "999" ]]; then
					score="$(printf "%'d" ${score})"
				fi
				views="${pageSrc#*\"views\":}"
				views="${views%%,*}" 
				if [[ "${views}" -gt "999" ]]; then
					views="$(printf "%'d" ${views})"
				fi
				if [[ "${nsfw,,}" == "true" ]]; then
					pageTitle="[NSFW] (${account}) ${title} | Uploaded ${created} | ${format} | ${comments} | ${views} views | ${score} Points"
				else
					pageTitle="(${account}) ${title} | Uploaded ${created} | ${format} | ${comments} | ${views} views | ${score} Points"
				fi
			elif [[ "${success,,}" == "false" ]]; then
				# It could be an album, or a non-gallery image
				pageSrc="$(curl -A "${nick}" -m 5 -k -s -L -H "Authorization: Client-ID ${imgurApi}" "https://api.imgur.com/3/gallery/album/${id}")"
				success="${pageSrc#*\"success\":}"
				success="${success%%,*}"
				n="0"
				while [[ -z "${success}" ]] && [[ "${n}" -lt "3" ]]; do
					sleep 1
					pageSrc="$(curl -A "${nick}" -m 5 -k -s -L -H "Authorization: Client-ID ${imgurApi}" "https://api.imgur.com/3/gallery/album/${id}")"
					success="${pageSrc#*\"success\":}"
					success="${success%%,*}"
					(( n++ ))
				done
				if [[ "${success,,}" == "true" ]]; then
					# It's an album
					nsfw="${pageSrc#*\"nsfw\":}"
					nsfw="${nsfw%%,*}"
					count="${pageSrc#*\"images_count\":}"
					count="${count%%,*}"
					if [[ "${count}" -gt "999" ]]; then
						count="$(printf "%'d" ${count})"
					fi
					title="${pageSrc#*\"title\":\"}"
					title="${title%%\",\"*}"
					title="${title//\\\"/\"}"
					created="${pageSrc#*\"datetime\":}"
					created="${created%%,*}"
					created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
					account="${pageSrc#*\"account_url\":\"}"
					account="${account%%\",\"*}"
					comments="${pageSrc#*\"comment_count\":}"
					comments="${comments%%,*}" 
					if [[ "${comments}" -eq "1" ]]; then
						comments="${comments} comment"
					elif [[ "${comments}" -gt "1" ]] && [[ "${comments}" -lt "1000" ]]; then
						comments="${comments} comments"
					elif [[ "${comments}" -ge "1000" ]]; then
						comments="$(printf "%'d" ${comments}) comments"
					else
						comments="You should never get this message! [Debug 4]"
					fi
					score="${pageSrc#*\"score\":}"
					score="${score%%,*}"
					if [[ "${score}" -gt "999" ]]; then
						score="$(printf "%'d" ${score})"
					fi
					views="${pageSrc#*\"views\":}"
					views="${views%%,*}" 
					if [[ "${views}" -gt "999" ]]; then
						views="$(printf "%'d" ${views})"
					fi
					if [[ "${nsfw,,}" == "true" ]]; then
						pageTitle="[NSFW] [Album | ${count} items] (${account}) ${title} | Uploaded ${created} | ${comments} | ${views} views | ${score} Points"
					else
						pageTitle="[Album | ${count} items] (${account}) ${title} | Uploaded ${created} | ${comments} | ${views} views | ${score} Points"
					fi
				elif [[ "${success,,}" == "false" ]]; then
					# It could be a non-gallery image
					pageSrc="$(curl -A "${nick}" -m 5 -k -s -L -H "Authorization: Client-ID ${imgurApi}" "https://api.imgur.com/3/image/${id}")"
					success="${pageSrc#*\"success\":}"
					success="${success%%,*}"
					if [[ "${success,,}" == "true" ]]; then
						# It's not a gallery image
						nsfw="${pageSrc#*\"nsfw\":}"
						nsfw="${nsfw%%,*}"
						created="${pageSrc#*\"datetime\":}"
						created="${created%%,*}"
						created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
						format="${pageSrc#*\"type\":\"}"
						format="${format%%\",*}"
						format="${format//\\\///}"
						title="${pageSrc#*\"title\":}"
						title="${title%%,\"*}"
						title="${title#\"}"
						title="${title%\"}"
						title="${title//\\\"/\"}"
						if [[ "${title,,}" == "null" ]]; then
							title="(No Title)"
						fi
						views="${pageSrc#*\"views\":}"
						views="${views%%,*}" 
						if [[ "${views}" -gt "999" ]]; then
							views="$(printf "%'d" ${views})"
						fi
						if [[ "${nsfw,,}" == "true" ]]; then
							pageTitle="[NSFW] (Anonymous) ${title} | Uploaded ${created} | ${format} | ${views} views"
						else
							pageTitle="(Anonymous) ${title} | Uploaded ${created} | ${format} | ${views} views"
						fi
					elif [[ "${success,,}" == "false" ]]; then
					# We have no idea what it is
						getTitle;
					fi
				else
					# Well now we've fucked up
					pageTitle="You should REALLY never get this error!"
				fi
			else
				# Well now we've fucked up
				type="unknown"
				pageTitle="You should REALLY REALLY never get this error!"
			fi
			echo "[Imgur] ${pageTitle}"
		done
	fi
}

instagram () {
	re="https?://(www\.)?instagram\.com/p/[[:alnum:]]+"
	re2="https?://(www\.)?instagram\.com/[[:alnum:]]+"
	if [[ "${url,,}" =~ ${re} ]]; then
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		if fgrep -q "<h2>Page Not Found</h2>" <<<"${pageSrc}"; then
			getTitle;
		else
			pageSrc="$(fgrep -m 1 "window._sharedData" <<<"${pageSrc}")"
			user="${pageSrc#*\"owner\":\{\"username\":}"
			user="${user%%,*}"
			user="${user#\"}"
			user="${user%\"}"
			if fgrep -q "\"caption\"" <<<"${pageSrc}"; then
				title="${pageSrc#*\"caption\":\"}"
				title="${title%%\",\"*}"
				title="$(sed -E "s/\\\u[0-9]{3}[a-z]//g" <<<"${title}")"
				title="$(sed -E "s/\\\u[0-9]{4}//g" <<<"${title}")"
				title="${title//\\\"/\"}"
				title="${title//\\\n/}"
				title="$(sed 's/\\\\/\\/g' <<<"${title}")"
				title="$(sed 's/\\\//\//g' <<<"${title}")"
			else
				title="[No Title]"
			fi
			likes="${pageSrc#*\"likes\":}"
			likes="${likes#*\"count\":}"
			likes="${likes%%,*}"
			if [[ "${likes}" -gt "999" ]]; then
				likes="$(printf "%'d" ${likes})"
			fi
			name="${pageSrc#*\"full_name\":}"
			name="${name%%,\"*}"
			name="${name#\"}"
			name="${name%\"}"
			if [[ "${name,,}" == "null" ]]; then
				name="[Anonymous]"
			else
				name="$(sed -E "s/\\\u[0-9]{3}[a-z]//g" <<<"${name}")"
				name="$(sed -E "s/\\\u[0-9]{4}//g" <<<"${name}")"
			fi
			created="${pageSrc#*\"date\":}"
			created="${created%%,*}"
			created="${created%.0}"
			created="$(date -d @${created} "+%a, %b %d, %Y @ %H:%M:%S")"
			pageTitle="${name} (@${user}) [${created}] | ${title} | ${likes} likes"
		fi
	elif [[ "${url,,}" =~ ${re2} ]]; then
		# Could be a profile?
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
		if fgrep -q "property=\"og:title\"" <<<"${pageSrc}"; then
			title="$(fgrep -m 1 "property=\"og:title\"" <<<"${pageSrc}")"
			title="${title#*content=\"}"
			title="${title% • Instagram photos and videos\"*}"
			pageSrc="$(fgrep -m 1 "window._sharedData" <<<"${pageSrc}")"
			pageSrc="${pageSrc##*\"counts\":\{}"
			pageSrc="${pageSrc%%\},}"
			pics="${pageSrc#*\"media\":}"
			pics="${pics%%,*}"
			followers="${pageSrc#*\"followed_by\":}"
			followers="${followers%%,*}"
			follows="${pageSrc#*\"follows\":}"
			follows="${follows%%\}*}"
			if [[ "${pics}" -gt "999" ]]; then
				pics="$(printf "%'d" ${pics})"
			fi
			if [[ "${followers}" -gt "999" ]]; then
				followers="$(printf "%'d" ${followers})"
			fi
			if [[ "${follows}" -gt "999" ]]; then
				follows="$(printf "%'d" ${follows})"
			fi
			pageTitle="${title} | ${pics} Pictures | ${followers} Followers | ${follows} Followed"
		else
			getTitle;
		fi
	else
		getTitle;
	fi
	echo "[Instagram] ${pageTitle}"
}

ckpastebin () {
	re="^http(s)?://(www\.)?captain-kickass\.net/p/view/(raw/|download/)?[[:alnum:]]+"
	if [[ "${url}" =~ ${re} ]]; then
		id="${url%/}"
		id="${id##*/}"
		id="${id%%#*}"
		id="${id%%\?*}"
		pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "https://captain-kickass.net/p/api/paste/${id}?apikey=${pbApiKey}")"
		if [[ "${pageSrc,,}" == '{"message":"not found"}' ]]; then
			pageTitle="(No such paste with ID ${id})"
		else
			lines="$(curl -A "${nick}" -m 5 -k -s -L "https://captain-kickass.net/p/view/raw/${id}" | wc -l)"
			(( lines++ ))
			if [[ "${lines}" -gt "999" ]]; then
				lines="$(printf "%'d" ${lines})"
			fi
			title="${pageSrc#*\"title\":}"
			title="${title%%,*}"
			title="${title#\"}"
			title="${title%\"}"
			author="${pageSrc#*\"name\":}"
			author="${author%%,*}"
			author="${author#\"}"
			author="${author%\"}"
			lang="${pageSrc#*\"lang\":}"
			lang="${lang%%,*}"
			lang="${lang#\"}"
			lang="${lang%\"}"
			hits="${pageSrc#*\"hits\":}"
			hits="${hits%%,*}"
			hits="${hits#\"}"
			hits="${hits%\"}"
			if [[ "${hits}" -gt "999" ]]; then
				hits="$(printf "%'d" ${hits})"
			fi
			pageTitle="${title} by ${author} | ${lang} | ${hits} views | ${lines} lines"
		fi
	else
		getTitle;
	fi
	echo "[Stikked] ${pageTitle}"
}

otherSite () {
	reqFullCurl="0"
	contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}")"
	contentHeader="${contentHeader///}"
	httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
	n="0"
	while [[ "${httpResponseCode}" -eq "502" ]] && [[ "${n}" -lt "5" ]]; do
		sleep ${n}
		contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
		contentHeader="${contentHeader///}"
		httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
		(( n++ ))
	done
	
	if [[ "${httpResponseCode}" -ne "200" ]]; then
		reqFullCurl="1"
		contentHeader="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}")"
		contentHeader="${contentHeader///}"
		httpResponseCode="$(egrep -i "HTTP/[0-9]\.[0-9] [0-9]{3}" <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
	fi
	
	# Zero means the location is true, no (httpd) redirect to the destination
	locationIsTrue="$(grep -i -c "Location:" <<<"${contentHeader}")"
	alreadyMatched="0"
	if [[ "${locationIsTrue}" -ne "0" ]]; then
		if [[ "${reqFullCurl}" -eq "1" ]]; then
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -o /dev/null -D - "${url}" | grep -i "Location:" | tail -n 1 | awk '{print $2}')"
		else
			pageDest="$(curl -A "${nick}" -m 5 -k -s -L -I "${url}" | grep -i "Location:" | tail -n 1 | awk '{print $2}')"
		fi
		url="${pageDest}"
		url="${url///}"
		echo "[URL] Redirects to: ${url}"
	else
		pageDest="${url}"
	fi

	if [[ "${locationIsTrue}" -eq "0" ]]; then
		catchAll;
	else
		checkKnownSites;
		if [[ "${matched}" -eq "0" ]]; then
			catchAll;
		fi
	fi
}
catchAll () {
	if [[ "${httpResponseCode}" -eq "200" ]]; then
		contentType="$(egrep -i "Content[ |-]Type:" <<<"${contentHeader}" | tail -n 1)"
		if fgrep -q "text/html" <<<"${contentType}"; then
			pageSrc="$(curl -A "${nick}" -m 5 -k -s -L "${url}")"
			getTitle;
		elif [[ "${alreadyMatched}" -eq "0" ]]; then
			contentMatches="$(fgrep -c "Content-Length" <<<"${contentHeader}")"
			if [[ "${contentMatches}" -eq "0" ]]; then
				pageTitle="${contentType} (Unable to determine size)"
			elif [[ "${contentMatches}" -eq "1" ]]; then
				contentLength="$(fgrep -i "Content-Length" <<<"${contentHeader}" | awk '{print $2}')"
				pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
				pageTitle="${contentType} (${pageSize})"
			else
				grepNum="1"
				contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${contentHeader}" | awk '{print $2}')"
				while [[ "${contentLength}" -eq "0" ]] && [[ "${grepNum}" -ne "${contentMatches}" ]]; do
					grepNum="$(( ${grepNum} + 1 ))"
					contentLength="$(fgrep -i "Content-Length" -m ${grepNum} <<<"${contentHeader}" | tail -n 1 | awk '{print $2}')"
				done
				if [[ "${contentLength}" -eq "0" ]]; then
					pageTitle="${contentType} (Unable to determine size)"
				else
					pageSize="$(awk '{ split( "B KB MB GB TB PB EB ZB YB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1), v[s] }' <<<"${contentLength}")"
					pageTitle="${contentType} (${pageSize})"
				fi
			fi
		fi
		if [[ -z "${pageDest}" ]]; then
			pageDest="[Unable to determine URL destination]"
		fi
	else
		if [[ -n "${httpResponseCode}" ]]; then
			pageTitle="Returned ${httpResponseCode}"
		fi
	fi
	echo "[URL] ${pageTitle}"
}

checkKnownSites () {
	matched="0"
	re="^http(s)?://((www\.)?youtube\.com|youtu\.be)"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		youtube;
	fi
	re="^http(s)?://(www\.)?newegg\.com"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		newegg;
	fi
	re="^http(s)?://(www\.|smile\.)?ama?zo?n\.(com|co\.uk|com\.au|de|fr|ca|cn|es|it)"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		amazon;
	fi
	re="^http(s)?://(www\.)?twitter\.com"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		twitter;
	fi
	re="^http(s)?://(www\.|beta\.)speedtest\.net"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		speedtest;
	fi
	re="^http(s)?://((store\.)?steampowered\.com|(www\.)?steamcommunity\.com)"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		steam;
	fi
	re="^http(s)?://([a-z]{2}\.|w{3}\.)wikipedia\.org"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		wikipedia;
	fi
	re="^http(s)?://((www\.)?reddit\.com)"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		reddit;
	fi
	re="^http(s)?://(www\.|i\.)?imgur\.com"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		imgur;
	fi
	re="^http(s)?://((www\.)?instagram\.com|instagr\.am)"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		instagram;
	fi
	re="^http(s)?://(www\.)?captain-kickass\.net/p/"
	if [[ "${matched}" -eq "0" ]] && [[ "${url,,}" =~ ${re,,} ]]; then
		matched="1"
		ckpastebin;
	fi
}

egrep -i -o "http(s)?://([[:alnum:]]|[[:punct:]])+" <<<"${msgArr[@]}" | while read url; do
	checkKnownSites;
	if [[ "${matched}" -eq "0" ]]; then
		otherSite;
	fi
done

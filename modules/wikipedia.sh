#!/usr/bin/env bash

## Config

## Source

# Check dependencies 
if [[ "$1" == "--dep-check" ]]; then
	depFail="0"
	deps=("curl")
	if [[ "${#deps[@]}" -ne "0" ]]; then
		for i in ${deps[@]}; do
			if ! command -v ${i} > /dev/null 2>&1; then
				echo -e "Missing dependency \"${red}${i}${reset}\"! Exiting."
				depFail="1"
			fi
		done
		if [[ "${depFail}" -eq "1" ]]; then
			exit 1
		else
			echo "ok"
			exit 0
		fi
	else
		echo "ok"
		exit 0
	fi
fi
modHook="Prefix"
modForm=("wiki" "wikipedia")
modFormCase=""
modHelp="Searches wikipedia for a query and returns the first result"
modFlag="m"
if [[ -z "${msgArr[4]}" ]]; then
	echo "This command requires a parameter"
else
	re="'"
	qry="${msgArr[@]:4}" qry="${qry//%/%25}"; qry="${qry// /%20}"; qry="${qry//!/%21}"; qry="${qry//\"/%22}"; qry="${qry//#/%23}"; qry="${qry//\$/%24}"; qry="${qry//\&/%26}"; qry="${qry//${re}/%27}"; qry="${qry//\(/%28}"; qry="${qry//\)/%29}"; qry="${qry//\*/%2A}"; qry="${qry//\+/%2B}"; qry="${qry//,/%2C}"; qry="${qry//-/%2D}"; qry="${qry//\./%2E}"; qry="${qry//\//%2F}"; qry="${qry//\:/%3A}"; qry="${qry//;/%3B}"; qry="${qry//</%3C}"; qry="${qry//=/%3D}"; qry="${qry//>/%3E}"; qry="${qry//\?/%3F}"; qry="${qry//@/%40}"; qry="${qry//\[/%5B}"; qry="${qry//\/%5C}"; qry="${qry//\]/%5D}"; qry="${qry//\^/%5E}"; qry="${qry//_/%5F}"; qry="${qry//\`/%60}"; qry="${qry//\{/%7B}"; qry="${qry//|/%7C}"; qry="${qry//\}/%7D}"; qry="${qry//~/%7E}"; qry="${qry//™/%99}"; qry="${qry//¡/%A1}"; qry="${qry//¢/%A2}"; qry="${qry//£/%A3}"; qry="${qry//¤/%A4}"; qry="${qry//¥/%A5}"; qry="${qry//¦/%A6}"; qry="${qry//§/%A7}"; qry="${qry//¨/%A8}"; qry="${qry//©/%A9}"; qry="${qry//ª/%AA}"; qry="${qry//«/%AB}"; qry="${qry//¬/%AC}"; qry="${qry//Soft/%AD}"; qry="${qry//®/%AE}"; qry="${qry//¯/%AF}"; qry="${qry//°/%B0}"; qry="${qry//±/%B1}"; qry="${qry//²/%B2}"; qry="${qry//³/%B3}"; qry="${qry//´/%B4}"; qry="${qry//µ/%B5}"; qry="${qry//¶/%B6}"; qry="${qry//·/%B7}"; qry="${qry//¸/%B8}"; qry="${qry//¹/%B9}"; qry="${qry//º/%BA}"; qry="${qry//»/%BB}"; qry="${qry//¼/%BC}"; qry="${qry//½/%BD}"; qry="${qry//¾/%BE}"; qry="${qry//¿/%BF}"; qry="${qry//À/%C0}"; qry="${qry//Á/%C1}"; qry="${qry//Â/%C2}"; qry="${qry//Ã/%C3}"; qry="${qry//Ä/%C4}"; qry="${qry//Å/%C5}"; qry="${qry//Æ/%C6}"; qry="${qry//Ç/%C7}"; qry="${qry//È/%C8}"; qry="${qry//É/%C9}"; qry="${qry//Ê/%CA}"; qry="${qry//Ë/%CB}"; qry="${qry//Ì/%CC}"; qry="${qry//Í/%CD}"; qry="${qry//Î/%CE}"; qry="${qry//Ï/%CF}"; qry="${qry//Ð/%D0}"; qry="${qry//Ñ/%D1}"; qry="${qry//Ò/%D2}"; qry="${qry//Ó/%D3}"; qry="${qry//Ô/%D4}"; qry="${qry//Õ/%D5}"; qry="${qry//Ö/%D6}"; qry="${qry//×/%D7}"; qry="${qry//Ø/%D8}"; qry="${qry//Ù/%D9}"; qry="${qry//Ú/%DA}"; qry="${qry//Û/%DB}"; qry="${qry//Ü/%DC}"; qry="${qry//Ý/%DD}"; qry="${qry//Þ/%DE}"; qry="${qry//ß/%DF}"; qry="${qry//à/%E0}"; qry="${qry//á/%E1}"; qry="${qry//â/%E2}"; qry="${qry//ã/%E3}"; qry="${qry//ä/%E4}"; qry="${qry//å/%E5}"; qry="${qry//æ/%E6}"; qry="${qry//ç/%E7}"; qry="${qry//è/%E8}"; qry="${qry//é/%E9}"; qry="${qry//ê/%EA}"; qry="${qry//ë/%EB}"; qry="${qry//ì/%EC}"; qry="${qry//í/%ED}"; qry="${qry//î/%EE}"; qry="${qry//ï/%EF}"; qry="${qry//ð/%F0}"; qry="${qry//ñ/%F1}"; qry="${qry//ò/%F2}"; qry="${qry//ó/%F3}"; qry="${qry//ô/%F4}"; qry="${qry//õ/%F5}"; qry="${qry//ö/%F6}"; qry="${qry//÷/%F7}"; qry="${qry//ø/%F8}"; qry="${qry//ù/%F9}"; qry="${qry//ú/%FA}"; qry="${qry//û/%FB}"; qry="${qry//ü/%FC}"; qry="${qry//ý/%FD}"; qry="${qry//þ/%FE}"; qry="${qry//ÿ/%FF}";
	searchResult="$(curl -s --get "https://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=site:en.wikipedia.org%20${qry}")"
	results="${searchResult#*\"results\":[}"
	results="${results%]*}"
	if [[ -z "${results}" ]]; then
		echo "No results found"
	else
		url="${searchResult#*\"unescapedUrl\":\"}"
		url="${url%%\"*}"
		title="${searchResult#*\"titleNoFormatting\":\"}"
		title="${title%%\"*}"
		desc="${searchResult#*\"content\":\"}"
		desc="${desc%%\"*}"
		desc="$(sed -r "s/\\\\u.{4}(b|\/b)?//g" <<<"${desc}")"
		desc="${desc//\\\n/}"
		desc="${desc//quot;/\"}"
		desc="${desc//amp;/&}"
		desc="${desc//lt;/<}"
		desc="${desc//gt;/>}"
desc="${desc//#33;/!}"; desc="${desc//#34;/\"}"; desc="${desc//#35;/#}"; desc="${desc//#36;/$}"; desc="${desc//#37;/%}"; desc="${desc//#38;/&}"; desc="${desc//#39;/${re}}"; desc="${desc//#40;/(}"; desc="${desc//#41;/)}"; desc="${desc//#42;/*}"; desc="${desc//#43;/+}"; desc="${desc//#44;/,}"; desc="${desc//#45;/-}"; desc="${desc//#46;/.}"; desc="${desc//#47;/\/}"; desc="${desc//#48;/0}"; desc="${desc//#49;/1}"; desc="${desc//#50;/2}"; desc="${desc//#51;/3}"; desc="${desc//#52;/4}"; desc="${desc//#53;/5}"; desc="${desc//#54;/6}"; desc="${desc//#55;/7}"; desc="${desc//#56;/8}"; desc="${desc//#57;/9}"; desc="${desc//#58;/:}"; desc="${desc//#59;/;}"; desc="${desc//#60;/<}"; desc="${desc//#61;/=}"; desc="${desc//#62;/>}"; desc="${desc//#63;/?}"; desc="${desc//#64;/@}"; desc="${desc//#65;/A}"; desc="${desc//#66;/B}"; desc="${desc//#67;/C}"; desc="${desc//#68;/D}"; desc="${desc//#69;/E}"; desc="${desc//#70;/F}"; desc="${desc//#71;/G}"; desc="${desc//#72;/H}"; desc="${desc//#73;/I}"; desc="${desc//#74;/J}"; desc="${desc//#75;/K}"; desc="${desc//#76;/L}"; desc="${desc//#77;/M}"; desc="${desc//#78;/N}"; desc="${desc//#79;/O}"; desc="${desc//#80;/P}"; desc="${desc//#81;/Q}"; desc="${desc//#82;/R}"; desc="${desc//#83;/S}"; desc="${desc//#84;/T}"; desc="${desc//#85;/U}"; desc="${desc//#86;/V}"; desc="${desc//#87;/W}"; desc="${desc//#88;/X}"; desc="${desc//#89;/Y}"; desc="${desc//#90;/Z}"; desc="${desc//#91;/[}"; desc="$(sed 's/#92;/\\/g' <<<"${desc}")" desc="${desc//#93;/]}"; desc="${desc//#94;/^}"; desc="${desc//#95;/_}"; desc="${desc//#96;/\`}"; desc="${desc//#97;/a}"; desc="${desc//#98;/b}"; desc="${desc//#99;/c}"; desc="${desc//#100;/d}"; desc="${desc//#101;/e}"; desc="${desc//#102;/f}"; desc="${desc//#103;/g}"; desc="${desc//#104;/h}"; desc="${desc//#105;/i}"; desc="${desc//#106;/j}"; desc="${desc//#107;/k}"; desc="${desc//#108;/l}"; desc="${desc//#109;/m}"; desc="${desc//#110;/n}"; desc="${desc//#111;/o}"; desc="${desc//#112;/p}"; desc="${desc//#113;/q}"; desc="${desc//#114;/r}"; desc="${desc//#115;/s}"; desc="${desc//#116;/t}"; desc="${desc//#117;/u}"; desc="${desc//#118;/v}"; desc="${desc//#119;/w}"; desc="${desc//#120;/x}"; desc="${desc//#121;/y}"; desc="${desc//#122;/z}"; desc="${desc//#123;/{}"; desc="${desc//#124;/|}"; desc="${desc//#125;/\}}"; desc="${desc//#126;/~}"; desc="${desc//#153;/™}"; desc="${desc//#161;/¡}"; desc="${desc//#162;/¢}"; desc="${desc//#163;/£}"; desc="${desc//#164;/¤}"; desc="${desc//#165;/¥}"; desc="${desc//#166;/¦}"; desc="${desc//#167;/§}"; desc="${desc//#168;/¨}"; desc="${desc//#169;/©}"; desc="${desc//#170;/ª}"; desc="${desc//#171;/«}"; desc="${desc//#172;/¬}"; desc="${desc//#173;/Soft}"; desc="${desc//#174;/®}"; desc="${desc//#175;/¯}"; desc="${desc//#176;/°}"; desc="${desc//#177;/±}"; desc="${desc//#178;/²}"; desc="${desc//#179;/³}"; desc="${desc//#180;/´}"; desc="${desc//#181;/µ}"; desc="${desc//#182;/¶}"; desc="${desc//#183;/·}"; desc="${desc//#184;/¸}"; desc="${desc//#185;/¹}"; desc="${desc//#186;/º}"; desc="${desc//#187;/»}"; desc="${desc//#188;/¼}"; desc="${desc//#189;/½}"; desc="${desc//#190;/¾}"; desc="${desc//#191;/¿}"; desc="${desc//#192;/À}"; desc="${desc//#193;/Á}"; desc="${desc//#194;/Â}"; desc="${desc//#195;/Ã}"; desc="${desc//#196;/Ä}"; desc="${desc//#197;/Å}"; desc="${desc//#198;/Æ}"; desc="${desc//#199;/Ç}"; desc="${desc//#200;/È}"; desc="${desc//#201;/É}"; desc="${desc//#202;/Ê}"; desc="${desc//#203;/Ë}"; desc="${desc//#204;/Ì}"; desc="${desc//#205;/Í}"; desc="${desc//#206;/Î}"; desc="${desc//#207;/Ï}"; desc="${desc//#208;/Ð}"; desc="${desc//#209;/Ñ}"; desc="${desc//#210;/Ò}"; desc="${desc//#211;/Ó}"; desc="${desc//#212;/Ô}"; desc="${desc//#213;/Õ}"; desc="${desc//#214;/Ö}"; desc="${desc//#215;/×}"; desc="${desc//#216;/Ø}"; desc="${desc//#217;/Ù}"; desc="${desc//#218;/Ú}"; desc="${desc//#219;/Û}"; desc="${desc//#220;/Ü}"; desc="${desc//#221;/Ý}"; desc="${desc//#222;/Þ}"; desc="${desc//#223;/ß}"; desc="${desc//#224;/à}"; desc="${desc//#225;/á}"; desc="${desc//#226;/â}"; desc="${desc//#227;/ã}"; desc="${desc//#228;/ä}"; desc="${desc//#229;/å}"; desc="${desc//#230;/æ}"; desc="${desc//#231;/ç}"; desc="${desc//#232;/è}"; desc="${desc//#233;/é}"; desc="${desc//#234;/ê}"; desc="${desc//#235;/ë}"; desc="${desc//#236;/ì}"; desc="${desc//#237;/í}"; desc="${desc//#238;/î}"; desc="${desc//#239;/ï}"; desc="${desc//#240;/ð}"; desc="${desc//#241;/ñ}"; desc="${desc//#242;/ò}"; desc="${desc//#243;/ó}"; desc="${desc//#244;/ô}"; desc="${desc//#245;/õ}"; desc="${desc//#246;/ö}"; desc="${desc//#247;/÷}"; desc="${desc//#248;/ø}"; desc="${desc//#249;/ù}"; desc="${desc//#250;/ú}"; desc="${desc//#251;/û}"; desc="${desc//#252;/ü}"; desc="${desc//#253;/ý}"; desc="${desc//#254;/þ}"; desc="${desc//#255;/ÿ}";
		echo "[Wikipedia] ${url} | ${title} | ${desc}"
	fi
fi
exit 0

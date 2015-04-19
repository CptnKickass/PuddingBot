#!/usr/bin/env bash

case "${msgArr[1]^^}" in
	NOTICE)
	if [[ "${msgArr[@]:3}" =~ ":*** Looking up your hostname..." ]]; then
		# Give the connection a second to register
		sleep 1
		if [[ -n "${serverpass}" ]]; then
				echo "NICK ${nick}" >> "${output}"
				echo "USER ${ident} +iwx * :${gecos}" >> "${output}"
				echo "PASS ${serverpass}" >> "${output}"
			else
				echo "NICK ${nick}" >> "${output}"
				echo "USER ${ident} +iwx * :${gecos}" >> "${output}"
		fi
		regSent="1"
	fi
	;;
	# 001 is WELCOME
	001)
	fullCon="1"
	networkName="${message#*Welcome to the }"
	if fgrep -q " Internet Relay Chat Network" <<<"${networkName}"; then
		networkName="${networkName% Internet Relay Chat Network*}"
	else
		networkName="${networkName% IRC Network*}"
	fi
	actualServer="${msgArr[0]}"
	actualServer="${actualServer#:}"
	echo "networkName=\"${networkName}\"" >> var/.status
	echo "actualServer=\"${actualServer}\"" >> var/.status
	;;
	# 002 is YOURHOST
	002)
	;;
	# 003 is CREATED
	003)
	;;
	# 004 is MYINFO
	004)
	;;
	# 005 is BOUNCE
	005)
	prefix="$(fgrep -i "PREFIX=" <<<"${msgArr[@]}")"
	if [[ -n "${prefix}" ]]; then
		prefixSym="${prefix,,}"
		prefixSym="${prefixSym#*prefix=(*)}"
		prefixSym="${prefixSym%% *}"
		echo "prefixSym=\"${prefixSym}\"" >> var/.status
		prefixLtr="${prefix,,}"
		prefixLtr="${prefixLtr#*prefix=(}"
		prefixLtr="${prefixLtr%%)*}"
		echo "prefixLtr=\"${prefixLtr}\"" >> var/.status
	fi
	;;
	# 006 is MAP
	006)
	;;
	# 007 is MAPEND
	007)
	;;
	# 008 is SNOMASK
	008)
	;;
	# 009 is STATMEMTOT
	009)
	;;
	# 010 is BOUNCE
	010)
	;;
	# 014 is YOURCOOKIE
	014)
	;;
	# 015 is MAP
	015)
	;;
	# 016 is MAPMORE
	016)
	;;
	# 017 is MAPEND
	017)
	;;
	# 042 is YOURID
	042)
	;;
	# 043 is SAVENICK
	043)
	;;
	# 050 is ATTEMPTINGJUNC
	050)
	;;
	# 051 is ATTEMPTINGREROUTE
	051)
	;;
	# 200 is TRACELINK
	200)
	;;
	# 201 is TRACECONNECTING
	201)
	;;
	# 202 is TRACEHANDSHAKE
	202)
	;;
	# 203 is TRACEUNKNOWN
	203)
	;;
	# 204 is TRACEOPERATOR
	204)
	;;
	# 205 is TRACEUSER
	205)
	;;
	# 206 is TRACESERVER
	206)
	;;
	# 207 is TRACESERVICE
	207)
	;;
	# 208 is TRACENEWTYPE
	208)
	;;
	# 209 is TRACECLASS
	209)
	;;
	# 210 is TRACERECONNECT
	210)
	;;
	# 211 is STATSLINKINFO
	211)
	;;
	# 212 is STATSCOMMANDS
	212)
	;;
	# 213 is STATSCLINE
	213)
	;;
	# 214 is STATSNLINE
	214)
	;;
	# 215 is STATSILINE
	215)
	;;
	# 216 is STATSKLINE
	216)
	;;
	# 217 is STATSQLINE
	217)
	;;
	# 218 is STATSYLINE
	218)
	;;
	# 219 is ENDOFSTATS
	219)
	;;
	# 220 is STATSPLINE
	220)
	;;
	# 221 is UMODEIS
	221)
	;;
	# 222 is MODLIST
	222)
	;;
	# 223 is STATSELINE
	223)
	;;
	# 224 is STATSFLINE
	224)
	;;
	# 225 is STATSDLINE
	225)
	;;
	# 226 is STATSCOUNT
	226)
	;;
	# 227 is STATSGLINE
	227)
	;;
	# 228 is STATSQLINE
	228)
	;;
	# 231 is SERVICEINFO
	231)
	;;
	# 232 is ENDOFSERVICES
	232)
	;;
	# 233 is SERVICE
	233)
	;;
	# 234 is SERVLIST
	234)
	;;
	# 235 is SERVLISTEND
	235)
	;;
	# 236 is STATSVERBOSE
	236)
	;;
	# 237 is STATSENGINE
	237)
	;;
	# 238 is STATSFLINE
	238)
	;;
	# 239 is STATSIAUTH
	239)
	;;
	# 240 is STATSVLINE
	240)
	;;
	# 241 is STATSLLINE
	241)
	;;
	# 242 is STATSUPTIME
	242)
	;;
	# 243 is STATSOLINE
	243)
	;;
	# 244 is STATSHLINE
	244)
	;;
	# 245 is STATSSLINE
	245)
	;;
	# 246 is STATSPING
	246)
	;;
	# 247 is STATSBLINE
	247)
	;;
	# 248 is STATSULINE
	248)
	;;
	# 249 is STATSULINE
	249)
	;;
	# 250 is STATSDLINE
	250)
	;;
	# 251 is LUSERCLIENT
	251)
	;;
	# 252 is LUSEROP
	252)
	;;
	# 253 is LUSERUNKNOWN
	253)
	;;
	# 254 is LUSERCHANNELS
	254)
	;;
	# 255 is LUSERME
	255)
	;;
	# 256 is ADMINME
	256)
	;;
	# 257 is ADMINLOC1
	257)
	;;
	# 258 is ADMINLOC2
	258)
	;;
	# 259 is ADMINEMAIL
	259)
	;;
	# 261 is TRACELOG
	261)
	;;
	# 262 is TRACEPING
	262)
	;;
	# 263 is TRYAGAIN
	263)
	;;
	# 265 is LOCALUSERS
	265)
	;;
	# 266 is GLOBALUSERS
	266)
	;;
	# 267 is START_NETSTAT
	267)
	;;
	# 268 is NETSTAT
	268)
	;;
	# 269 is END_NETSTAT
	269)
	;;
	# 270 is PRIVS
	270)
	;;
	# 271 is SILELIST
	271)
	;;
	# 272 is ENDOFSILELIST
	272)
	;;
	# 273 is NOTIFY
	273)
	;;
	# 274 is ENDNOTIFY
	274)
	;;
	# 275 is STATSDLINE
	275)
	;;
	# 276 is VCHANEXIST
	276)
	;;
	# 277 is VCHANLIST
	277)
	;;
	# 278 is VCHANHELP
	278)
	;;
	# 280 is GLIST
	280)
	;;
	# 281 is ENDOFGLIST
	281)
	;;
	# 282 is ENDOFACCEPT
	282)
	;;
	# 283 is ALIST
	283)
	;;
	# 284 is ENDOFALIST
	284)
	;;
	# 285 is GLIST_HASH
	285)
	;;
	# 286 is CHANINFO_USERS
	286)
	;;
	# 287 is CHANINFO_CHOPS
	287)
	;;
	# 288 is CHANINFO_VOICES
	288)
	;;
	# 289 is CHANINFO_AWAY
	289)
	;;
	# 290 is CHANINFO_OPERS
	290)
	;;
	# 291 is CHANINFO_BANNED
	291)
	;;
	# 292 is CHANINFO_BANS
	292)
	;;
	# 293 is CHANINFO_INVITE
	293)
	;;
	# 294 is CHANINFO_INVITES
	294)
	;;
	# 295 is CHANINFO_KICK
	295)
	;;
	# 296 is CHANINFO_KICKS
	296)
	;;
	# 299 is END_CHANINFO
	299)
	;;
	# 300 is NONE
	300)
	;;
	# 301 is AWAY
	301)
	;;
	# 302 is USERHOST
	302)
	;;
	# 303 is ISON
	303)
	;;
	# 304 is TEXT
	304)
	;;
	# 305 is UNAWAY
	305)
	;;
	# 306 is NOWAWAY
	306)
	;;
	# 307 is USERIP
	307)
	;;
	# 308 is NOTIFYACTION
	308)
	;;
	# 309 is NICKTRACE
	309)
	;;
	# 310 is WHOISSVCMSG
	310)
	;;
	# 311 is WHOISUSER
	311)
	;;
	# 312 is WHOISSERVER
	312)
	;;
	# 313 is WHOISOPERATOR
	313)
	;;
	# 314 is WHOWASUSER
	314)
	;;
	# 315 is ENDOFWHO
	315)
	;;
	# 316 is WHOISCHANOP
	316)
	;;
	# 317 is WHOISIDLE
	317)
	;;
	# 318 is ENDOFWHOIS
	318)
	;;
	# 319 is WHOISCHANNELS
	319)
	;;
	# 320 is WHOISVIRT
	320)
	;;
	# 321 is LISTSTART
	321)
	;;
	# 322 is LIST
	322)
	;;
	# 323 is LISTEND
	323)
	;;
	# 324 is CHANNELMODEIS
	324)
	;;
	# 325 is UNIQOPIS
	325)
	;;
	# 326 is NOCHANPASS
	326)
	;;
	# 327 is CHPASSUNKNOWN
	327)
	;;
	# 328 is CHANNEL_URL
	328)
	;;
	# 329 is CREATIONTIME
	329)
	;;
	# 330 is WHOWAS_TIME
	330)
	;;
	# 331 is NOTOPIC
	331)
	;;
	# 332 is TOPIC
	332)
	;;
	# 333 is TOPICWHOTIME
	333)
	;;
	# 334 is LISTUSAGE
	334)
	;;
	# 335 is WHOISBOT
	335)
	;;
	# 338 is CHANPASSOK
	338)
	;;
	# 339 is BADCHANPASS
	339)
	;;
	# 340 is USERIP
	340)
	;;
	# 341 is INVITING
	341)
	;;
	# 342 is SUMMONING
	342)
	;;
	# 345 is INVITED
	345)
	;;
	# 346 is INVITELIST
	346)
	;;
	# 347 is ENDOFINVITELIST
	347)
	;;
	# 348 is EXCEPTLIST
	348)
	;;
	# 349 is ENDOFEXCEPTLIST
	349)
	;;
	# 351 is VERSION
	351)
	;;
	# 352 is WHOREPLY
	352)
	;;
	# 353 is NAMREPLY
	353)
	if ! [[ -d "var/.track" ]]; then
		mkdir "var/.track"
	fi
	msgArr[5]="${msgArr[5]#:}"
	for i in "${msgArr[@]:5}"; do
		echo "${i}" >> "var/.track/${msgArr[4],,}"
	done
	;;
	# 354 is WHOSPCRPL
	354)
	;;
	# 355 is NAMREPLY_
	355)
	;;
	# 357 is MAP
	357)
	;;
	# 358 is MAPMORE
	358)
	;;
	# 359 is MAPEND
	359)
	;;
	# 361 is KILLDONE
	361)
	;;
	# 362 is CLOSING
	362)
	;;
	# 363 is CLOSEEND
	363)
	;;
	# 364 is LINKS
	364)
	;;
	# 365 is ENDOFLINKS
	365)
	;;
	# 366 is ENDOFNAMES
	366)
	;;
	# 367 is BANLIST
	367)
	;;
	# 368 is ENDOFBANLIST
	368)
	;;
	# 369 is ENDOFWHOWAS
	369)
	;;
	# 371 is INFO
	371)
	;;
	# 372 is MOTD
	372)
	;;
	# 373 is INFOSTART
	373)
	;;
	# 374 is ENDOFINFO
	374)
	;;
	# 375 is MOTDSTART
	375)
	if [[ -n "${operId}" ]] && [[ -n "${operPass}" ]]; then
		echo "OPER ${operId} ${operPass}"
		if [[ -n "${operModes}" ]]; then
			echo "MODE ${nick} ${operModes}" >> "${output}"
		fi
	fi
	if [[ -n "${nickPass}" ]]; then
		echo "PRIVMSG NickServ :identify ${nickPass}" >> "${output}"
		nickPassSent="1"
	fi
	for item in ${channels[*]}; do
		reqNames="1"
		echo "JOIN ${item}" >> "${output}"
		echo "${item,,}" >> "var/.inchan"
		date +%s > "var/.last/${item,,}"
		if [[ "${logIn}" -eq "1" ]]; then
			source ./bin/core/log.sh --start
		fi
	done
	if [[ -n "${lastCom}" ]]; then
		echo "${lastCom}" >> ${output}
	fi
	;;
	# 376 is ENDOFMOTD
	376)
	;;
	# 377 is KICKEXPIRED
	377)
	;;
	# 378 is BANEXPIRED
	378)
	;;
	# 379 is KICKLINKED
	379)
	;;
	# 380 is BANLINKED
	380)
	;;
	# 381 is YOUREOPER
	381)
	;;
	# 382 is REHASHING
	382)
	;;
	# 383 is YOURESERVICE
	383)
	;;
	# 384 is MYPORTIS
	384)
	;;
	# 385 is NOTOPERANYMORE
	385)
	;;
	# 386 is QLIST
	386)
	;;
	# 387 is ENDOFQLIST
	387)
	;;
	# 388 is ALIST
	388)
	;;
	# 389 is ENDOFALIST
	389)
	;;
	# 391 is TIME
	391)
	;;
	# 392 is USERSSTART
	392)
	;;
	# 393 is USERS
	393)
	;;
	# 394 is ENDOFUSERS
	394)
	;;
	# 395 is NOUSERS
	395)
	;;
	# 396 is HOSTHIDDEN
	396)
	;;
	# 400 is ERR_UNKNOWNERROR
	400)
	;;
	# 401 is ERR_NOSUCHNICK
	401)
	;;
	# 402 is ERR_NOSUCHSERVER
	402)
	;;
	# 403 is ERR_NOSUCHCHANNEL
	403)
	;;
	# 404 is ERR_CANNOTSENDTOCHAN
	404)
	;;
	# 405 is ERR_TOOMANYCHANNELS
	405)
	;;
	# 406 is ERR_WASNOSUCHNICK
	406)
	;;
	# 407 is ERR_TOOMANYTARGETS
	407)
	;;
	# 408 is ERR_NOSUCHSERVICE
	408)
	;;
	# 409 is ERR_NOORIGIN
	409)
	;;
	# 411 is ERR_NORECIPIENT
	411)
	;;
	# 412 is ERR_NOTEXTTOSEND
	412)
	;;
	# 413 is ERR_NOTOPLEVEL
	413)
	;;
	# 414 is ERR_WILDTOPLEVEL
	414)
	;;
	# 415 is ERR_BADMASK
	415)
	;;
	# 416 is ERR_TOOMANYMATCHES
	416)
	;;
	# 419 is ERR_LENGTHTRUNCATED
	419)
	;;
	# 421 is ERR_UNKNOWNCOMMAND
	421)
	;;
	# 422 is ERR_NOMOTD
	422)
	;;
	# 423 is ERR_NOADMININFO
	423)
	;;
	# 424 is ERR_FILEERROR
	424)
	;;
	# 425 is ERR_NOOPERMOTD
	425)
	;;
	# 429 is ERR_TOOMANYAWAY
	429)
	;;
	# 430 is ERR_EVENTNICKCHANGE
	430)
	;;
	# 431 is ERR_NONICKNAMEGIVEN
	431)
	;;
	# 432 is ERR_ERRONEUSNICKNAME
	432)
	echo "Invalid nick"
	;;
	# 433 is ERR_NICKNAMEINUSE
	433)
	;;
	# 434 is ERR_SERVICENAMEINUSE
	434)
	;;
	# 435 is ERR_SERVICECONFUSED
	435)
	;;
	# 436 is ERR_NICKCOLLISION
	436)
	;;
	# 437 is ERR_UNAVAILRESOURCE
	437)
	;;
	# 438 is ERR_NICKTOOFAST
	438)
	;;
	# 439 is ERR_TARGETTOOFAST
	439)
	;;
	# 440 is ERR_SERVICESDOWN
	440)
	;;
	# 441 is ERR_USERNOTINCHANNEL
	441)
	;;
	# 442 is ERR_NOTONCHANNEL
	442)
	;;
	# 443 is ERR_USERONCHANNEL
	443)
	;;
	# 444 is ERR_NOLOGIN
	444)
	;;
	# 445 is ERR_SUMMONDISABLED
	445)
	;;
	# 446 is ERR_USERSDISABLED
	446)
	;;
	# 447 is ERR_NONICKCHANGE
	447)
	;;
	# 449 is ERR_NOTIMPLEMENTED
	449)
	;;
	# 451 is ERR_NOTREGISTERED
	451)
	;;
	# 452 is ERR_IDCOLLISION
	452)
	;;
	# 453 is ERR_NICKLOST
	453)
	;;
	# 455 is ERR_HOSTILENAME
	455)
	;;
	# 456 is ERR_ACCEPTFULL
	456)
	;;
	# 457 is ERR_ACCEPTEXIST
	457)
	;;
	# 458 is ERR_ACCEPTNOT
	458)
	;;
	# 459 is ERR_NOHIDING
	459)
	;;
	# 460 is ERR_NOTFORHALFOPS
	460)
	;;
	# 461 is ERR_NEEDMOREPARAMS
	461)
	;;
	# 462 is ERR_ALREADYREGISTERED
	462)
	;;
	# 463 is ERR_NOPERMFORHOST
	463)
	;;
	# 464 is ERR_PASSWDMISMATCH
	464)
	;;
	# 465 is ERR_YOUREBANNEDCREEP
	465)
	;;
	# 466 is ERR_YOUWILLBEBANNED
	466)
	;;
	# 467 is ERR_KEYSET
	467)
	;;
	# 468 is ERR_INVALIDUSERNAME
	468)
	;;
	# 469 is ERR_LINKSET
	469)
	;;
	# 470 is ERR_LINKCHANNEL
	470)
	;;
	# 471 is ERR_CHANNELISFULL
	471)
	;;
	# 472 is ERR_UNKNOWNMODE
	472)
	;;
	# 473 is ERR_INVITEONLYCHAN
	473)
	;;
	# 474 is ERR_BANNEDFROMCHAN
	474)
	;;
	# 475 is ERR_BADCHANNELKEY
	475)
	;;
	# 476 is ERR_BADCHANMASK
	476)
	;;
	# 477 is ERR_NOCHANMODES
	477)
	;;
	# 478 is ERR_BANLISTFULL
	478)
	;;
	# 479 is ERR_BADCHANNAME
	479)
	;;
	# 480 is ERR_NOULINE
	480)
	;;
	# 481 is ERR_NOPRIVILEGES
	481)
	;;
	# 482 is ERR_CHANOPRIVSNEEDED
	482)
	;;
	# 483 is ERR_CANTKILLSERVER
	483)
	;;
	# 484 is ERR_RESTRICTED
	484)
	;;
	# 485 is ERR_UNIQOPRIVSNEEDED
	485)
	;;
	# 486 is ERR_NONONREG
	486)
	;;
	# 487 is ERR_CHANTOORECENT
	487)
	;;
	# 488 is ERR_TSLESSCHAN
	488)
	;;
	# 489 is ERR_VOICENEEDED
	489)
	;;
	# 491 is ERR_NOOPERHOST
	491)
	;;
	# 492 is ERR_NOSERVICEHOST
	492)
	;;
	# 493 is ERR_NOFEATURE
	493)
	;;
	# 494 is ERR_BADFEATURE
	494)
	;;
	# 495 is ERR_BADLOGTYPE
	495)
	;;
	# 496 is ERR_BADLOGSYS
	496)
	;;
	# 497 is ERR_BADLOGVALUE
	497)
	;;
	# 498 is ERR_ISOPERLCHAN
	498)
	;;
	# 499 is ERR_CHANOWNPRIVNEEDED
	499)
	;;
	# 501 is ERR_UMODEUNKNOWNFLAG
	501)
	;;
	# 502 is ERR_USERSDONTMATCH
	502)
	;;
	# 503 is ERR_GHOSTEDCLIENT
	503)
	;;
	# 504 is ERR_USERNOTONSERV
	504)
	;;
	# 511 is ERR_SILELISTFULL
	511)
	;;
	# 512 is ERR_TOOMANYWATCH
	512)
	;;
	# 513 is ERR_BADPING
	513)
	;;
	# 514 is ERR_INVALID_ERROR
	514)
	;;
	# 515 is ERR_BADEXPIRE
	515)
	;;
	# 516 is ERR_DONTCHEAT
	516)
	;;
	# 517 is ERR_DISABLED
	517)
	;;
	# 518 is ERR_NOINVITE
	518)
	;;
	# 519 is ERR_ADMONLY
	519)
	;;
	# 520 is ERR_OPERONLY
	520)
	;;
	# 521 is ERR_LISTSYNTAX
	521)
	;;
	# 522 is ERR_WHOSYNTAX
	522)
	;;
	# 523 is ERR_WHOLIMEXCEED
	523)
	;;
	# 524 is ERR_QUARANTINED
	524)
	;;
	# 525 is ERR_REMOTEPFX
	525)
	;;
	# 526 is ERR_PFXUNROUTABLE
	526)
	;;
	# 550 is ERR_BADHOSTMASK
	550)
	;;
	# 551 is ERR_HOSTUNAVAIL
	551)
	;;
	# 552 is ERR_USINGSLINE
	552)
	;;
	# 553 is ERR_STATSSLINE
	553)
	;;
	# 600 is LOGON
	600)
	;;
	# 601 is LOGOFF
	601)
	;;
	# 602 is WATCHOFF
	602)
	;;
	# 603 is WATCHSTAT
	603)
	;;
	# 604 is NOWON
	604)
	;;
	# 605 is NOWOFF
	605)
	;;
	# 606 is WATCHLIST
	606)
	;;
	# 607 is ENDOFWATCHLIST
	607)
	;;
	# 608 is WATCHCLEAR
	608)
	;;
	# 610 is MAPMORE
	610)
	;;
	# 611 is ISLOCOP
	611)
	;;
	# 612 is ISNOTOPER
	612)
	;;
	# 613 is ENDOFISOPER
	613)
	;;
	# 615 is MAPMORE
	615)
	;;
	# 616 is WHOISHOST
	616)
	;;
	# 617 is DCCSTATUS
	617)
	;;
	# 618 is DCCLIST
	618)
	;;
	# 619 is ENDOFDCCLIST
	619)
	;;
	# 620 is DCCINFO
	620)
	;;
	# 621 is RULES
	621)
	;;
	# 622 is ENDOFRULES
	622)
	;;
	# 623 is MAPMORE
	623)
	;;
	# 624 is OMOTDSTART
	624)
	;;
	# 625 is OMOTD
	625)
	;;
	# 626 is ENDOFO
	626)
	;;
	# 630 is SETTINGS
	630)
	;;
	# 631 is ENDOFSETTINGS
	631)
	;;
	# 640 is DUMPING
	640)
	;;
	# 641 is DUMPRPL
	641)
	;;
	# 642 is EODUMP
	642)
	;;
	# 660 is TRACEROUTE_HOP
	660)
	;;
	# 661 is TRACEROUTE_START
	661)
	;;
	# 662 is MODECHANGEWARN
	662)
	;;
	# 663 is CHANREDIR
	663)
	;;
	# 664 is SERVMODEIS
	664)
	;;
	# 665 is OTHERUMODEIS
	665)
	;;
	# 666 is ENDOF_GENERIC
	666)
	;;
	# 670 is WHOWASDETAILS
	670)
	;;
	# 671 is WHOISSECURE
	671)
	;;
	# 672 is UNKNOWNMODES
	672)
	;;
	# 673 is CANNOTSETMODES
	673)
	;;
	# 678 is LUSERSTAFF
	678)
	;;
	# 679 is TIMEONSERVERIS
	679)
	;;
	# 682 is NETWORKS
	682)
	;;
	# 687 is YOURLANGUAGEIS
	687)
	;;
	# 688 is LANGUAGE
	688)
	;;
	# 689 is WHOISSTAFF
	689)
	;;
	# 690 is WHOISLANGUAGE
	690)
	;;
	# 702 is MODLIST
	702)
	;;
	# 703 is ENDOFMODLIST
	703)
	;;
	# 704 is HELPSTART
	704)
	;;
	# 705 is HELPTXT
	705)
	;;
	# 706 is ENDOFHELP
	706)
	;;
	# 708 is ETRACEFULL
	708)
	;;
	# 709 is ETRACE
	709)
	;;
	# 710 is KNOCK
	710)
	;;
	# 711 is KNOCKDLVR
	711)
	;;
	# 712 is ERR_TOOMANYKNOCK
	712)
	;;
	# 713 is ERR_CHANOPEN
	713)
	;;
	# 714 is ERR_KNOCKONCHAN
	714)
	;;
	# 715 is ERR_KNOCKDISABLED
	715)
	;;
	# 716 is TARGUMODEG
	716)
	;;
	# 717 is TARGNOTIFY
	717)
	;;
	# 718 is UMODEGMSG
	718)
	;;
	# 720 is OMOTDSTART
	720)
	;;
	# 721 is OMOTD
	721)
	;;
	# 722 is ENDOFOMOTD
	722)
	;;
	# 723 is ERR_NOPRIVS
	723)
	;;
	# 724 is TESTMARK
	724)
	;;
	# 725 is TESTLINE
	725)
	;;
	# 726 is NOTESTLINE
	726)
	;;
	# 771 is XINFO
	771)
	;;
	# 773 is XINFOSTART
	773)
	;;
	# 774 is XINFOEND
	774)
	;;
	# 900 is InspIRCd replying with what NickServ account you've successfully identified to
	900)
	;;
	# 931 is InspIRCd telling us they don't tolerate spam bots
	931)
	;;
	# 972 is ERR_CANNOTDOCOMMAND
	972)
	;;
	# 973 is ERR_CANNOTCHANGEUMODE
	973)
	;;
	# 974 is ERR_CANNOTCHANGECHANMODE
	974)
	;;
	# 975 is ERR_CANNOTCHANGESERVERMODE
	975)
	;;
	# 976 is ERR_CANNOTSENDTONICK
	976)
	;;
	# 977 is ERR_UNKNOWNSERVERMODE
	977)
	;;
	# 979 is ERR_SERVERMODELOCK
	979)
	;;
	# 980 is ERR_BADCHARENCODING
	980)
	;;
	# 981 is ERR_TOOMANYLANGUAGES
	981)
	;;
	# 982 is ERR_NOLANGUAGE
	982)
	;;
	# 983 is ERR_TEXTTOOSHORT
	983)
	;;
	# 999 is ERR_NUMERIC_ERR
	999)
	;;
	# Server is setting a mode
	MODE)
		;;
	# It's a snotice
	NOTICE)
		;;
	# It's wallops
	WALLOPS)
		;;
	# It's a PRIVMSG
	PRIVMSG)
		;;
	*)
		echo "$(date -R) [${0}] ${msgArr[@]}" >> $(<var/bot.pid).debug
		;;
esac

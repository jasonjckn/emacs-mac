;; -*- mode: lisp-data; -*-
((pass 10 "PASS :barnet:changeme"))
((nick 10 "NICK tester"))
((user 0.2 "USER user 0 * :tester")
 (0 ":irc.barnet.org 001 tester :Welcome to the barnet IRC Network tester")
 (0 ":irc.barnet.org 002 tester :Your host is irc.barnet.org, running version oragono-2.5.1-4860c5cad0179db1")
 (0 ":irc.barnet.org 003 tester :This server was created Fri, 19 Mar 2021 10:23:19 UTC")
 (0 ":irc.barnet.org 004 tester irc.barnet.org oragono-2.5.1-4860c5cad0179db1 BERTZios CEIMRUabefhiklmnoqstuv Iabefhkloqv")
 (0 ":irc.barnet.org 005 tester AWAYLEN=390 BOT=B CASEMAPPING=ascii CHANLIMIT=#:100 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 CHANTYPES=# ELIST=U EXCEPTS EXTBAN=,m INVEX KICKLEN=390 MAXLIST=beI:60 :are supported by this server")
 (0 ":irc.barnet.org 005 tester MAXTARGETS=4 MODES MONITOR=100 NETWORK=barnet NICKLEN=32 PREFIX=(qaohv)~&@%+ STATUSMSG=~&@%+ TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 TOPICLEN=390 UTF8MAPPING=rfc8265 UTF8ONLY WHOX draft/CHATHISTORY=100 :are supported by this server")
 (0 ":irc.barnet.org 251 tester :There are 0 users and 1 invisible on 1 server(s)")
 (0 ":irc.barnet.org 252 tester 0 :IRC Operators online")
 (0 ":irc.barnet.org 254 tester 0 :channels formed")
 (0 ":irc.barnet.org 255 tester :I have 1 clients and 0 servers")
 (0 ":irc.barnet.org 265 tester 1 1 :Current local users 1, max 1")
 (0 ":irc.barnet.org 266 tester 1 1 :Current global users 1, max 1")
 (0 ":irc.barnet.org 422 tester :MOTD File is missing"))

((mode-user 10.2 "MODE tester +i")
 ;; No mode answer
 (0 ":irc.znc.in 306 tester :You have been marked as being away")
 (0 ":tester!~u@8cgjyczyrjgby.irc JOIN #bar")
 (0 ":irc.barnet.org 353 tester = #bar :@mike joe tester")
 (0 ":irc.barnet.org 366 tester #bar :End of /NAMES list.")
 (0 ":***!znc@znc.in PRIVMSG #bar :Buffer Playback...")
 (0 ":joe!~u@8cgjyczyrjgby.irc PRIVMSG #bar :[10:23:28] tester, welcome!")
 (0 ":mike!~u@8cgjyczyrjgby.irc PRIVMSG #bar :[10:23:28] tester, welcome!")
 (0 ":joe!~u@8cgjyczyrjgby.irc PRIVMSG #bar :[10:24:49] mike: Bid me farewell, and let me hear thee going.")
 (0 ":mike!~u@8cgjyczyrjgby.irc PRIVMSG #bar :[10:24:54] joe: By heaven, thy love is black as ebony.")
 (0 ":***!znc@znc.in PRIVMSG #bar :Playback Complete.")
 (0 ":irc.barnet.org NOTICE tester :[10:23:22] This server is in debug mode and is logging all user I/O. If you do not wish for everything you send to be readable by the server owner(s), please disconnect.")
 (0 ":irc.barnet.org 305 tester :You are no longer marked as being away"))

((mode 20 "MODE #bar")
 (0 ":irc.barnet.org 324 tester #bar +nt")
 (0 ":irc.barnet.org 329 tester #bar 1616149403")
 (0.1 ":mike!~u@8cgjyczyrjgby.irc PRIVMSG #bar :joe: To ask of whence you are: report it.")
 (0.1 ":joe!~u@8cgjyczyrjgby.irc PRIVMSG #bar :mike: Friar, thou knowest not the duke so well as I do: he's a better woodman than thou takest him for.")
 (0.1 ":mike!~u@8cgjyczyrjgby.irc PRIVMSG #bar :joe: Like the sequel, I. Signior Costard, adieu.")
 (0.1 ":joe!~u@8cgjyczyrjgby.irc PRIVMSG #bar :mike: This is his second fit; he had one yesterday."))

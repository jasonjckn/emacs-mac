;; -*- mode: lisp-data; -*-
((pass 5 "PASS :changeme"))
((nick 1 "NICK tester"))
((user 1 "USER tester@vanilla/foonet 0 * :tester")
 (0.01 ":soju.im 001 tester :Welcome to soju, tester")
 (0.02 ":soju.im 002 tester :Your host is soju.im")
 (0.01 ":soju.im 004 tester soju.im soju aiwroO OovaimnqpsrtklbeI")
 (0.00 ":soju.im 005 tester CHATHISTORY=1000 CASEMAPPING=ascii BOUNCER_NETID=1 CHANTYPES=# PREFIX=(qaohv)~&@%+ UTF8ONLY AWAYLEN=390 NICKLEN=32 WHOX CHANLIMIT=#:100 INVEX NETWORK=foonet MODES :are supported")
 (0.00 ":soju.im 005 tester TOPICLEN=390 BOT=B ELIST=U MAXLIST=beI:60 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 TARGMAX=NAMES:1,LIST:1,KICK:,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 EXCEPTS EXTBAN=,m KICKLEN=390 MAXTARGETS=4 MONITOR=100 :are supported")
 (0.00 ":soju.im 221 tester +Zi")
 (0.00 ":soju.im 422 tester :Use /motd to read the message of the day"))

((mode 5 "MODE tester +i")
 (0.2 ":irc.foonet.org 221 tester +Zi")
 (0.0 ":tester!tester@10.0.2.100 JOIN #chan")
 (0.0 ":soju.im 353 tester = #chan :tester @alice bob")
 (0.1 ":soju.im 366 tester #chan :End of /NAMES list")
 (0.0 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Princely shall be thy usage every way.")
 (0.1 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Tell me thy reason why thou wilt marry."))

((mode 5 "MODE #chan")
 (0.00 ":soju.im 324 tester #chan +nt")
 (0.01 ":soju.im 329 tester #chan 1652878847")
 (0.02 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: There is no leprosy but what thou speak'st.")
 (0.09 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: For I upon this bank will rest my head.")
 (0.01 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: To ruffle in the commonwealth of Rome.")
 (0.08 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: For I can nowhere find him like a man.")
 (0.09 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Ay, sir; but she will none, she gives you thanks.")
 (0.05 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: That man should be at woman's command, and yet no hurt done! Though honesty be no puritan, yet it will do no hurt; it will wear the surplice of humility over the black gown of a big heart. I am going, forsooth: the business is for Helen to come hither.")
 (0.07 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Indeed, I should have asked you that before.")
 (0.09 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Faith, we met, and found the quarrel was upon the seventh cause.")
 (0.05 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: And then, I hope, thou wilt be satisfied.")
 (0.06 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Well, I will forget the condition of my estate, to rejoice in yours.")
 (0.05 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Ah! sirrah, this unlook'd-for sport comes well.")
 (0.01 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Mayst thou inherit too! Welcome to Paris.")
 (0.04 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: That I would choose, were I to choose anew.")
 (0.08 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Good Tom Drum, lend me a handkercher: so, I thank thee. Wait on me home, I'll make sport with thee: let thy curtsies alone, they are scurvy ones.")
 (0.06 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Excellent workman! Thou canst not paint a man so bad as is thyself.")
 (0.07 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: That every braggart shall be found an ass.")
 (0.07 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: This is but a custom in your tongue; you bear a graver purpose, I hope.")
 (0.02 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: Well, we will have such a prologue, and it shall be written in eight and six.")
 (0.01 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Tell me thy reason why thou wilt marry.")
 (0.06 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: According to the measure of their states.")

 ;; Unexpected disconnect
 (0.07 ":BouncerServ!BouncerServ@BouncerServ NOTICE tester :disconnected from foonet: failed to handle messages: failed to read IRC command: read tcp [::1]:57224->[::1]:6667: read: software caused connection abort")
 ;; Eventual reconnect
 (1.02 ":BouncerServ!BouncerServ@BouncerServ NOTICE tester :connected to foonet")
 ;; No MOTD or other numerics
 (0.01 ":soju.im 005 tester AWAYLEN=390 BOT=B CHANLIMIT=#:100 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 CHANTYPES=# ELIST=U EXCEPTS EXTBAN=,m INVEX KICKLEN=390 :are supported")
 (0.02 ":soju.im 005 tester MAXLIST=beI:60 MAXTARGETS=4 MODES MONITOR=100 NETWORK=foonet NICKLEN=32 PREFIX=(qaohv)~&@%+ TARGMAX=NAMES:1,LIST:1,KICK:,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 TOPICLEN=390 UTF8ONLY WHOX :are supported")
 (0.02 ":irc.foonet.org 221 tester +Zi")
 (0.23 ":irc.foonet.org NOTICE tester :This server is in debug mode and is logging all user I/O. If you do not wish for everything you send to be readable by the server owner(s), please disconnect.")
 ;; Server-initialed join
 (0.02 ":tester!tester@10.0.2.100 JOIN #chan"))

((mode 5 "MODE #chan")
 (0.03 ":soju.im 353 tester = #chan :@alice bob tester")
 (0.03 ":soju.im 366 tester #chan :End of /NAMES list")
 (0.00 ":soju.im 324 tester #chan +nt")
 (0.00 ":soju.im 329 tester #chan 1652878847")
 (0.00 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :tester, welcome!")
 (0.00 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :tester, welcome!")
 (0.46 ":soju.im 324 tester #chan +nt")
 (0.01 ":soju.im 329 tester #chan 1652878847")
 (0.00 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: Thou desirest me to stop in my tale against the hair.")
 (0.07 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: But my intents are fix'd and will not leave me.")
 (0.09 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: That last is true; the sweeter rest was mine.")
 (0.09 ":alice!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :bob: No matter whither, so you come not here.")
 (0.09 ":bob!~u@h35cf3bf7rbt4.irc PRIVMSG #chan :alice: My lord, in heart; and let the health go round."))

((linger 12 LINGER))

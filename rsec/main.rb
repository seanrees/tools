# Ruby IRC Server
#
# $Id$

require "irc/irc_server"
require "irc/user_manager"
require "support/system_logger"

require "logger"

require "chanakill/chan_akill.rb"

# setup logger
logger = Logger.new("rsec.log", "daily")
logger.level = Logger::DEBUG
SystemLogger::add(logger)

irc = IrcServer.new("support.test.esper.net", "Support Server (prototype)", '9SS')

UserManager.new(irc)
ChanAkill.new(irc)

irc.connect("127.0.0.1", 8889, 'yoyo', 'frisbie')

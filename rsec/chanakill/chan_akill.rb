# Ruby IRC server
#
# $Id$

require "irc/irc_client"
require "irc/user_manager"
require "support/system_logger"

require "set"

class ChanAkill < IrcClient
  attr_accessor :channels

  def initialize(server)
    @user_name = "chanakill"
    @real_name = "Channel Akill Bot"
    @nick      = "ChanAkillCtrl"

    @channels = Set.new(%w(#espero_car ##main##))
    @logger = SystemLogger::get(self.class.to_s)

    server.on("SJOIN", self.method("do_sjoin"))

    server.register(self)
  end

  def do_privmsg(server, source, command, args)
    # ignore
  end

  def do_sjoin(server, source, command, args)
    params = args.split(" ")
    channel = params[1]
    uid     = params[3][1..-1]

    # trim off @ sign
    uid = uid[1..-1] if uid[0,1] == "@"
    user = UserManager::get(uid)

    if user.nil?
      @logger.error("unknown user #{uid} joined a channel")
    else
      @logger.info(
        "restricted channel join #{user.nick} (#{uid}) to #{channel}"
      ) if @channels.include?(channel)
    end
  end
end

# Ruby IRC server
#
# $Id$

require "set"
require "thread"

require "irc/irc_errors"
require "support/system_logger"

class User
  attr_accessor :uid, :nick, :ts, :mode, :host, :ip, :user_name, :real_name

  def to_s
    return "{ uid=#{@uid}, nick=#{@nick}, ts=#{@ts}, mode=#{@mode}, host=#{@host}, ip=#{@ip}, user_name=#{@user_name}, real_name=#{@real_name} }"
  end
end

class UserManager
  class << self
    def get(uid)
      return @@users[uid]
    end
  end

  def initialize(server)
    @@users = Hash.new
    @@users_mutex = Mutex.new

    @logger = SystemLogger::get(self.class.to_s)

    server.on("UID",  self.method("do_uid"))
    server.on("MODE", self.method("do_mode"))
    server.on("NICK", self.method("do_nick"))
    server.on("QUIT", self.method("do_quit"))
  end

  def do_uid(server, source, command, args)
    params = args.split(" ", 9)

    user = User.new
    user.nick      = params[0]
    user.ts        = params[2]
    user.mode      = params[3][1..-1]  # trim +
    user.user_name = params[4]
    user.host      = params[5]
    user.ip        = params[6]
    user.uid       = params[7]
    user.real_name = params[8][1..-1]  # remove colon

    @@users_mutex.synchronize { @@users[user.uid] = user }

    @logger.debug("new user added: #{user.uid} nick=#{user.nick}")
  end

  def do_mode(server, source, command, args)
    params     = args.split(" ")
    uid        = params[0]
    change_str = params[1][1..-1]    # trim colon

    return if (uid[0,1] == "#")

    user    = self::get(uid);

    if user.nil?
      @logger.error("attempted mode change on non-existent user #{uid}")
    else
      changes = Set.new(change_str.split(""))
      modes   = Set.new(user.mode.split(""))

      # merge in new modes
      method = nil
      changes.each do |sym|
        if (sym == "-")
          method = modes.method("delete")
        elsif (sym == "+")
          method = modes.method("add")
        else
          method.call(sym) unless method.nil?
        end
      end

      modes_str = modes.to_a.sort.join("")

      @logger.debug("new mode for #{user.nick} = #{modes_str} acquiring lock")
      @@users_mutex.synchronize { user.mode = modes_str }
      @logger.debug("new mode for #{user.nick} = #{modes_str} complete")

    end
  end

  def do_nick(server, source, commands, args)
    params = args.split(" ")

    uid      = source
    new_nick = params[0]
    ts       = params[1][1..-1] # trim colon

    user = @@users[uid]

    if user.nil?
      @logger.error("nick change for non-existent user #{uid}")
    else
      @@users_mutex.synchronize {
        old_nick = user.nick

        user.nick = new_nick
        user.ts = ts

        @logger.debug("nick change #{old_nick} -> #{new_nick}")
      }
    end
  end

  def do_quit(server, source, commands, args)
    uid = source
    old_nick = nil

    @@users_mutex.synchronize {
      user = @@users[uid]

      if user.nil?
        @@users.delete(uid)
        @logger.debug("user quit #{source} nick=#{old_nick}")
      else
        @logger.error("user quit for non-existent user #{uid}")
      end
    }
  end
end

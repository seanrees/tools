# Ruby IRC client
#
# $Id$

class IrcClient
  attr_reader :user_name, :real_name, :nick

  def initialize(server)
    @user_name = "service"
    @real_name = "rsec client"
    @nick = "rsec"

    # register your own handlers

    # register ourselves
    #server.register(self)
  end

  # will be called for you when your client is messaged
  def do_privmsg(server, source, command, args)
    raise IrcException.new("not implemented")
  end
end

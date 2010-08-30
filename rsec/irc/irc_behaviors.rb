# Ruby IRC server
#
# $Id$

class IrcBehaviors
  def initialize(server)
    @server = server
    server.on("ADMIN",    self.method("do_admin"))
    server.on("MOTD",     self.method("do_motd"))
    server.on("VERSION",  self.method("do_version"))
  end

  # events
  def do_admin(server, source, command, args)
    server.send(":#{server.sid} 256 #{source} :Administrative info about #{server.name}")
    server.send(":#{server.sid} 257 #{source} :Prototype IRC server framework.")
    server.send(":#{server.sid} 258 #{source} :Copyright 2009 Sean Rees")
    server.send(":#{server.sid} 259 #{source} :sean@rees.us")
  end

  def do_motd(server, source, commands, args)
    server.send(":#{server.sid} 375 #{source} :- #{server.name} Message of the Day -")

    if (File.readable?("ircd.motd"))
      lines = IO.readlines("ircd.motd")
      for line in lines
        server.send(":#{server.sid} 372 #{source} :- #{line}")
      end
    else
      server.send(":#{server.sid} 372 #{source} :- This server has no MOTD.")
    end

    server.send(":#{server.sid} 376 #{source} :- End of /MOTD command.")
  end

  def do_version(server, source, commands, args)
    server.send(":#{server.sid} 351 #{source} rsec-0.1. #{server.name} :it's special!")
  end
end

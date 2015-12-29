require 'lib/irc/irc_command.rb'
require 'lib/irc/irc_commands.rb'

class PingCommand < IrcCommand
    def process(connection, input)
        command, args = input.split(" ")

        connection.out.puts "PONG #{args}"
    end
end

IrcCommands::register('PING', PingCommand.new)

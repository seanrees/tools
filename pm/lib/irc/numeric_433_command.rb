require 'lib/irc/irc_command.rb'
require 'lib/irc/irc_commands.rb'
require 'lib/irc/irc_error.rb'

class Numeric433Command < IrcCommand
    def process(connection, input)
        raise IrcError.new("nickname already in use")
    end
end

IrcCommands::register('433', Numeric433Command.new)

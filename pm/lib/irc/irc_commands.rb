class IrcCommands
    @@commands = {}

    def IrcCommands.register(command, handler)
        @@commands[command] = handler
    end

    def IrcCommands.handle(command, connection, input)
        handler = @@commands[command]

        handler.process(connection, input) unless handler.nil?
    end
end

require 'test/unit'
require 'lib/irc/irc_command.rb'
require 'lib/irc/irc_commands.rb'

class IrcCommandsTest < Test::Unit::TestCase
    class MockIrcCommand < IrcCommand
        attr_accessor :input

        def process(connection, input)
            @input = input
        end
    end

    def test_one
        command = MockIrcCommand.new
        IrcCommands::register('TEST', command)

        IrcCommands::handle('TEST', nil, 'input 1234')
        assert_equal('input 1234', command.input)
    end

    def test_none
        command = MockIrcCommand.new
        IrcCommands::handle('TEST', nil, 'input 1234')
        assert_nil(command.input)
    end

    def test_multi
        command_one = MockIrcCommand.new
        command_two = MockIrcCommand.new

        IrcCommands::register('ONE', command_one)
        IrcCommands::register('TWO', command_two)

        IrcCommands::handle('ONE', nil, 'test 1')
        assert_equal('test 1', command_one.input)

        IrcCommands::handle('TWO', nil, 'test 2')
        assert_equal('test 2', command_two.input)

        # make sure they didn't change
        assert_equal('test 1', command_one.input)
        assert_equal('test 2', command_two.input)
    end
end

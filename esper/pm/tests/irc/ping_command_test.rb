require 'test/unit'
require 'tests/irc/PipeConnectionTest'

require 'lib/irc/ping_command.rb'
require 'lib/irc/pipe_irc_connection.rb'

class PingCommandTest < Test::Unit::TestCase
    include PipeConnectionTest

    def test_process
        command = PingCommand.new
        command.process(@connection, "PING :abcdefg")
        @connection.out.close

        assert_equal("PONG :abcdefg", @connection.out_read.read.rstrip)
    end
end

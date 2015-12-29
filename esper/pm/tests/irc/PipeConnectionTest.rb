require 'lib/irc/pipe_irc_connection.rb'

module PipeConnectionTest
    def setup
        @connection = PipeIrcConnection.new
        @connection.open
    end

    def teardown
        @connection.close
    end
end

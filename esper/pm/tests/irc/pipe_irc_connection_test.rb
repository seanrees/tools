require 'test/unit'
require 'tests/irc/PipeConnectionTest'

require 'lib/irc/pipe_irc_connection.rb'

class PipeIrcConnectionTest < Test::Unit::TestCase
    include PipeConnectionTest

    def test_out
        @connection.out.write "test 123"
        @connection.out.close

        assert_equal("test 123", @connection.out_read.read)
    end

    def test_in
        @connection.in_write.write "test 123"
        @connection.in_write.close

        assert_equal("test 123", @connection.in.read)
    end
end

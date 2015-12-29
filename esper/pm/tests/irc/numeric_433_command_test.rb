require 'test/unit'

require 'lib/irc/irc_error.rb'
require 'lib/irc/numeric_433_command.rb'

class Numeric433CommandTest < Test::Unit::TestCase
    def test_process
        command = Numeric433Command.new
        assert_raise(IrcError) { command.process(nil, nil) }
    end
end

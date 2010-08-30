require 'test/unit'
require 'lib/server_pool.rb'

class ServerPoolTest < Test::Unit::TestCase
    def test_constructor
        assert_raise(RuntimeError) { ServerPool.new(nil) }
        assert_raise(RuntimeError) { ServerPool.new("") }
        assert_raise(RuntimeError) { ServerPool.new([]) }
        assert_nothing_raised { ServerPool.new({}) }
    end

    def test_server_list
        pool = ServerPool.new({
            "irc" => %w[ dream paradox triton ],
            "irc.us" => %w[ dream paradox ],
            "irc.eu" => %w[ triton ]
        })

        assert_equal(pool.server_list.sort, %w[dream paradox triton].sort, "server list not the same")

        pool = ServerPool.new({})
        assert(pool.server_list.size == 0)
    end

    def test_pools
        pool = ServerPool.new({
            "irc" => %w[ dream paradox triton ],
            "irc.us" => %w[ dream paradox ],
            "irc.eu" => %w[ triton ]
        })

        assert_equal(pool.pools("triton").sort, %w[irc irc.eu].sort, "server not in correct pools")
        assert_equal(pool.pools("paradox").sort, %w[irc irc.us].sort, "server not in correct pools")
    end
end

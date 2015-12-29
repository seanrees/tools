require 'test/unit'
require 'lib/dns_updater.rb'

class DnsUpdaterTest < Test::Unit::TestCase
    class DnsUpdaterProxy < DnsUpdater
        # proxy send_commands to private method
        def send_commands(io)
            _send_commands(io)
        end
    end

    def setup
        @updater = DnsUpdater.new(nil, nil, nil)
    end

    def test_constructor
        assert_equal(@updater.commands.size, 0, 'commands not empty')
    end

    def test_add
        @updater.add('test.com', '127.0.0.1', 'A', 1000)
        assert_equal(@updater.commands.size, 1, 'command size not == 1')
        assert_equal(@updater.commands[0], 'update add test.com. 1000 A 127.0.0.1')

        @updater.add('ipv6.test.com', '2001:dead::beef', 'AAAA', 1000)
        assert_equal(@updater.commands.size, 2, 'command size not == 2')
        assert_equal(@updater.commands[1], 'update add ipv6.test.com. 1000 AAAA 2001:dead::beef')
    end

    def test_add_all
        @updater.add_all([ 'test.com', 'test2.com' ], '127.0.0.1', 'A', 1000)
        assert_equal(@updater.commands.size, 2, 'command size not == 2')
        assert_equal(@updater.commands[0], 'update add test.com. 1000 A 127.0.0.1')
        assert_equal(@updater.commands[1], 'update add test2.com. 1000 A 127.0.0.1')
    end

    def test_delete
        @updater.delete('test.com', '127.0.0.1', 'A')
        assert_equal(@updater.commands.size, 1, 'command size not == 1')
        assert_equal(@updater.commands[0], 'update delete test.com. A 127.0.0.1')

        @updater.delete('ipv6.test.com', '2001:dead::beef', 'AAAA')
        assert_equal(@updater.commands.size, 2, 'command size not == 2')
        assert_equal(@updater.commands[1], 'update delete ipv6.test.com. AAAA 2001:dead::beef')
    end

    def test_delete_all
        @updater.delete_all([ 'test.com', 'test2.com' ], '127.0.0.1', 'A')
        assert_equal(@updater.commands.size, 2, 'command size not == 2')
        assert_equal(@updater.commands[0], 'update delete test.com. A 127.0.0.1')
        assert_equal(@updater.commands[1], 'update delete test2.com. A 127.0.0.1')
    end

    def test_order
        @updater.add('test.com', '127.0.0.1', 'A', 1000)
        @updater.delete('ipv6.test.com', '2001:dead::beef', 'AAAA')

        assert_equal(@updater.commands.size, 2, 'command size not == 2')
        assert_equal(@updater.commands[0], 'update add test.com. 1000 A 127.0.0.1', 'messages not in order')
        assert_equal(@updater.commands[1], 'update delete ipv6.test.com. AAAA 2001:dead::beef', 'messages not in order')
    end

    def test_send_commands
        updater = DnsUpdaterProxy.new(nil, nil, 'test.server')

        read, write = IO.pipe

        updater.add('test.com', '127.0.0.1', 'A', 1000)
        updater.delete('ipv6.test.com', '2001:dead::beef', 'AAAA')

        updater.send_commands(write)
        write.close

        lines = read.readlines
        assert_equal(lines[0].rstrip, 'server test.server')
        assert_equal(lines[1].rstrip, 'update add test.com. 1000 A 127.0.0.1')
        assert_equal(lines[2].rstrip, 'update delete ipv6.test.com. AAAA 2001:dead::beef')
        assert_equal(lines[3].rstrip, 'send')
        assert_equal(lines[4].rstrip, 'quit')
    end
end

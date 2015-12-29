require 'socket'
require 'test/unit'

require 'lib/irc/irc_client.rb'
require 'lib/irc/tcp_irc_connection.rb'

require 'logger'

class IrcClientTest < Test::Unit::TestCase
    def setup
        @server = TCPServer.new(0)
        @port   = @server.addr[1]

        @irc    = nil

        @client = Thread.new {
            log = Logger.new(STDERR)

            conn = TcpIrcConnection.new("localhost", @port)
            @irc  = IrcClient.new(conn, 'user', 'nick', 'gecos')
            @irc.log = log
            @irc.start
        }
    end

    def teardown
        @server.close
    end

    def test_connect
        server = Thread.new {
            sock = @server.accept

            assert_equal('USER user * * :gecos', sock.gets.rstrip)
            assert_equal('NICK nick', sock.gets.rstrip)

            sock.close
        }

        server.run
        @client.run

        server.join
    end

    def test_nickname
        server = Thread.new {
            sock = @server.accept

            sock.puts(":localhost 433 :Nickname nick is in use")
        }

        server.run
        @client.run

        server.join
        @client.join

        assert(! @irc.running?, "client is still running")
    end

    def test_quit
        server = Thread.new {
            sock = @server.accept
            sock.readlines
        }

        server.run
        @client.run

        @irc.stop
        assert(! @irc.running?, "client is still running")
    end
end

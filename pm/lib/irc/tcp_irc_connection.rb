require 'socket'
require 'lib/irc/irc_connection.rb'

class TcpIrcConnection < IrcConnection
    attr_accessor :host, :port

    def initialize(host, port = 6667)
        @host = host
        @port = port
    end

    def open
        @socket = TCPSocket.new(@host, @port)
        @in = @socket
        @out = @socket
    end

    def close
        @socket.close unless @socket.closed?
    end
end

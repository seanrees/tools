require 'lib/irc/irc_connection.rb'

class PipeIrcConnection < IrcConnection
    attr_accessor :in_write, :out_read

    def initialize
    end

    def open
        in_read, in_write = IO.pipe
        out_read, out_write = IO.pipe

        @in = in_read
        @out = out_write

        @in_write = in_write
        @out_read = out_read
    end

    def close
        @in.close unless @in.closed?
        @out.close unless @out.closed?
        @in_write.close unless @in_write.closed?
        @out_read.close unless @out_read.closed?
    end
end

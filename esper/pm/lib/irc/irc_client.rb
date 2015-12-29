require 'date'
require 'lib/irc/irc_commands.rb'
require 'lib/irc/irc_connection.rb'
require 'lib/irc/irc_error.rb'

require 'lib/fixnum_mixins.rb'

# TODO: put this in a better place
require 'lib/irc/ping_command.rb'
require 'lib/irc/numeric_433_command.rb'

class IrcClient
    attr_accessor :connection, :username, :nick, :realname, :log, :connect_time

    def initialize(connection, username, nick, realname)
        @connection = connection
        @username = username
        @nick = nick
        @realname = realname
        @connect_time = nil
    end

    def process(line)
        args = line.split(" ")
        command = nil

        if (args[0][0,1] == ':')
            # server message
            command = args[1]
        else
            command = args[0]
        end

        IrcCommands::handle(command, @connection, line)
    end

    def start
        server_name = "#{@connection.host}:#{@connection.port}"

        @log.info "connecting to #{server_name}" unless @log.nil?
        begin
            @connection.open
        rescue
            @log.info "connection to #{server_name} failed" unless @log.nil?
            return false
        end

        @log.info "connected to #{server_name}" unless @log.nil?

        @connect_time = Time.now

        @connection.out.puts("USER #{@username} * * :#{@realname}")
        @connection.out.puts("NICK #{@nick}")

        begin
            sock = @connection.in
            last = Time.now.to_i

            loop do
                res = select([ sock ], nil, nil, 1.minutes)
                now = Time.now.to_i

                # timeout or end-of-file
                if res.nil? and last + 2.minutes <= now
                    @log.info "timeout (#{now - last} seconds) from #{server_name}" unless @log.nil?
                    break
                end

                next if res.nil?

                line = sock.gets

                break if line.nil? and sock.eof?

                process line

                last = now
            end

            @log.info "disconnected from #{server_name}" unless @log.nil?
        rescue IrcError => ex
            @log.error "Error from #{server_name}: #{ex.message}" unless @log.nil?
        rescue Exception => ex
            @log.error "Error reading from #{server_name}: #{ex.message}" unless @log.nil?
        end

        @connection.close
        true
    end

    def stop
        @connection.out.puts("QUIT")
        @connection.close
    end

    def running?
        ((not @connection.nil?) and (not @connection.out.nil?) and (not @connection.out.closed?))
    end
end

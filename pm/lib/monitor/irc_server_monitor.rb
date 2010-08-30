require 'date'
require 'lib/irc/irc_client.rb'

class IrcServerMonitor
    attr_accessor :log, :name, :connection, :start_time, :first_failed, :last_failed, :fail_count, :last_connect

    def initialize(name, connection)
        @name       = name
        @connection = connection

        reset
        @last_connect = 0
        @stop = false
    end

    def connected?
        (not @client.nil?) and (@client.running?)
    end

    def reset
        @fail_count = 0
        @first_failed = nil
        @last_failed = nil
    end

    def start
        _start
    end

    def stop
        @stop = true
        @client.stop
    end

    def last_successful_connect
        @client.connect_time
    end

    def ever_connected?
        @client.connect_time.nil?
    end

    private
    def random_nick
        return 'eribot-' + @name + "-" + rand(99999).to_s
    end

    def _start
        @start_time = Time.now
        @client = IrcClient.new(connection, 'monitor', 'monitornick', 'server monitor')
        @client.log = @log

        loop do
            @client.nick = random_nick

            @last_connect = Time.now
            @client.start

            break if @stop

            # if start returns, the connection has failed
            @first_failed = Time.now if @fail_count == 0
            @fail_count += 1
            @last_failed = Time.now

            @log.info "connection to #{name} failed, will retry" unless @log.nil?

            # sleep for a few seconds before we reconnect
            Kernel.sleep(15)
        end
    end
end

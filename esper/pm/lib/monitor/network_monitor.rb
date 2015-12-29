require 'lib/irc/tcp_irc_connection.rb'
require 'lib/monitor/irc_server_monitor.rb'
require 'lib/fixnum_mixins.rb'

class NetworkMonitor
    attr_accessor :log, :server_list, :domain, :rules

    THREAD_CHECK_INTERVAL_SECS = 30

    def initialize(server_list, domain)
        @server_list = server_list
        @domain = domain

        @unstable = []
        @events = { }

        @stop = false
    end

    def start
        start_monitor
    end

    def stop
        @stop = true
    end

    def on(event, f)
        list = @events[event]

        list = Array.new if list.nil?

        list.push f
        @events[event] = list
    end

    def fire(event, monitor)
        list = @events[event]

        unless list.nil?
            list.each { |f|
                f.call(monitor)
            }
        end
    end

    private
    def build_monitors
        monitors = []
        server_list.each { |server|
            connection = TcpIrcConnection.new("#{server}.#{@domain}")
            monitor = IrcServerMonitor.new(server, connection)
            monitor.log = @log

            monitors.push(monitor)
            Thread.new { monitor.start }.run
        }
        monitors
    end

    def start_monitor
        @monitors = build_monitors

        loop do
            break if @stop

            check_threads
            Kernel.sleep(THREAD_CHECK_INTERVAL_SECS)
        end
    end

    def is_stable(monitor)
        six_hours_ago = Time.now.to_i - 6.hours

        monitor.connected? and six_hours_ago > monitor.last_connect.to_i
    end

    def is_unstable(monitor)
        five_minutes_ago = Time.now.to_i - 5.minutes

        # TODO: fix me!

        if monitor.fail_count >= 10
            @log.warn "#{monitor.name} has failed #{monitor.fail_count} times" unless @log.nil?
            return true
        elsif monitor.fail_count >= 5 and five_minutes_ago < monitor.first_failed.to_i
            @log.warn "#{monitor.name} has failed #{monitor.fail_count} over the last #{five_minutes_ago / 1.minutes} minutes" unless @log.nil?

            return true
        elsif ! monitor.ever_connected? and five_minutes_ago > monitor.start_time.to_i
            @log.warn "#{monitor.name} has not connected in the last #{five_minutes_ago / 1.minutes} minutes since start" unless @log.nil?

            return true
        elsif monitor.ever_connected? and five_minutes_ago > monitor.last_successful_connect.to_i
            @log.warn "#{monitor.name} has not successfully connected in the last #{five_minutes_ago / 1.minutes} minutes" unless @log.nil?

            return true
        else
            return false
    end

    def check_threads
        unstable = []

        @monitors.each { |monitor|
            if is_stable(monitor) and @unstable.include?(monitor)
                @log.info "#{monitor.name} has stabilized, resetting counters" unless @log.nil?
                @unstable.delete(monitor)
                monitor.reset

                fire("stable", monitor)
            end

            unstable.push(monitor) if is_unstable(monitor)
        }

        if (unstable.size <= 2)
            unstable.each { |monitor|
                unless @unstable.include?(monitor)
                    @unstable.push(monitor)
                    fire("unstable", monitor)
                end
            }
        else
            @log.warn "detected #{unstable.size} unstable servers, are we offline?" unless @log.nil?
        end
    end
end

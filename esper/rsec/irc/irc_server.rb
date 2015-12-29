# Ruby IRC Server
#
# $Id$

require "socket"
require "thread"
require "irc/irc"
require "irc/irc_errors"
require "irc/irc_behaviors"

class IrcServer
  attr_reader :clients, :events, :name, :description, :sid, :local_ip
  include Irc

  def initialize(name, description, sid, local_ip = nil)
    @clients     = Array.new
    @events      = Hash.new

    @name        = name
    @description = description
    @sid         = sid
    @local_ip    = local_ip
    @uid         = "#{sid}AAAAAA"

    @logger      = SystemLogger::get(self.class.to_s)
  end

  def connect(server, port, send_pass, accept_pass)
    @socket = TCPSocket::new(server, port, local_ip, nil)

    @socket.write("PASS #{send_pass} TS 6 #{@sid}\n")
    @socket.write("CAPAB :TBURST TB\n")
    @socket.write("SERVER #{@name} 1 :#{@description}\n")

    # default handlers
    on("PING", Proc.new { |server, source, command, args|
      server.send(":#{server.sid} PONG #{server.name} :#{@connected_to}")
    })

    on("PASS", Proc.new { |server, source, command, args|
      params = args.split(" ")
      if (params[0] == accept_pass)
        @logger.info("password from remote server accepted\n")
      else
        raise IrcError.new("incorrect accept password")
      end
    })

    on("SERVER", Proc.new { |server, source, command, args|
      params = args.split(" ")
      @connected_to = params[0]

      @logger.info("connected to #{@connected_to}\n")

      # connect clients
      @clients.each { |client| add_user(client) }
    })

    IrcBehaviors.new(self)

    run
  end

  def register(client)
    @logger.debug("registering client #{client.nick}")

    @clients.push(client)

    # add new clients if we're connected
    add_user(client) unless @socket.nil? || @socket.closed?
  end

  def on(message, handler)
    @events[message] = Array.new unless @events.has_key?(message)

    @events[message].push(handler)
  end

  def send(command)
    @logger.debug("sending: #{command}")

    @socket.write("#{command}\n")
  end

  def shutdown
    @logger.info("shutting down")

    @workers.list { |t|
      t.join
    }

    @socket.close
  end

  private
  def start_workers
    @workers = ThreadGroup.new

    for i in 1..3
      t = Thread.new {
        Thread.current["name"] = "worker#{i}"

        @logger.info("Starting worker #{i}")

        while 1
          until @in_msg_queue.empty?
            message = nil
            @in_msg_mutex.synchronize {
                message = @in_msg_queue.shift
            }

            benchmark("message processed in") {
              process(message)
            }
          end

          #@logger.debug("thread sleep")
          sleep(0.25)
        end
      }

      t.run

      @workers.add(t)
    end
  end

  def run
    @in_msg_queue = Array.new
    @in_msg_mutex = Mutex.new

    start_workers

    while 1
      begin
        res = select([ @socket ], nil, nil)

        for sock in res[0]
          if sock.eof? then
            @logger.info("connection closed by peer")
            shutdown
            break

          else
            str = sock.gets

            @in_msg_mutex.synchronize { @in_msg_queue.push(str) }
          end
        end
      rescue Exception => ex
        @logger.fatal("select interrupted: #{ex.message}")
        shutdown
        return
      end
    end # while
  end

  def process(line)
    line.chop!

    (command, args) = line.split(" ", 2)
    source = nil

    @logger.debug("peer said: #{line}")

    if (command[0,1] == ":")
      shift_args = args
      source = command[1..-1]    # trim off the colon

      (command, args) = shift_args.split(" ", 2)
    end

    if @events.has_key?(command)
      @logger.debug("sending events for #{command}")

      for handler in @events[command]
        begin
          handler.call(self, source, command, args)
        rescue IrcException => ex
          @logger.error(ex.message)
        rescue IrcError => err
          @logger.fatal(err.message)
          shutdown
        end
      end
    end
  end

  def add_user(client)
    nick = client.nick
    real = client.real_name
    user = client.user_name
    uid  = @uid.next!

    @logger.debug("adding client #{nick}")

    send(":#{@sid} UID #{nick} 1 #{timestamp} +io #{user} #{@name} 127.0.0.1 #{uid} :#{real}")
  end

  def benchmark(message, &block)
    start = Time.now
    yield
    stop  = Time.now

    diff = (stop.to_f - start.to_f) * 1000

    @logger.debug(sprintf("%s %0.4f ms", message, diff))
  end
end

class DnsUpdater
    attr_accessor :commands, :log

    def initialize(nsupdate, keyfile, server)
        @nsupdate = nsupdate
        @keyfile = keyfile
        @server = server

        @commands = Array.new
    end

    def add(fqdn, address, type, ttl)
        @log.info "Adding #{address} to #{fqdn} (type #{type}, ttl #{ttl})" unless @log.nil?

        @commands.push("update add #{fqdn}. #{ttl} #{type} #{address}")
    end

    def add_all(fqdns, address, type, ttl)
        fqdns.each { |fqdn|
            add(fqdn, address, type, ttl)
        }
    end

    def delete(fqdn, address, type)
        @log.info "Deleting #{address} from #{fqdn} (type #{type})" unless @log.nil?

        @commands.push("update delete #{fqdn}. #{type} #{address}")
    end

    def delete_all(fqdns, address, type)
        fqdns.each { |fqdn|
            delete(fqdn, address, type)
        }
    end

    def send
        @log.info 'Sending updates...'

        IO.popen("#{@nsupdate} -k #{@keyfile}", 'w') { |io|
            _send_commands(io)
        }
    end

    private
    def _send_commands(io)
        io.puts("server #{@server}")

        @commands.each { |command|
            io.puts(command)
         }

        io.puts("send")
        io.puts("quit")
    end
end

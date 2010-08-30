require 'yaml'
require 'lib/dns_updater.rb'
require 'lib/server_pool.rb'

class Config
    def initialize(config_filename)
        File.open(config_filename, 'r') { |file|
           @config = YAML::load(file)
        }
    end

    def domain
        return @config['domain']
    end

    def default_ttl
        return @config['default_ttl']
    end

    def mail_server
        return @config['mail']['server']
    end

    def mail_port
        return @config['mail']['port']
    end

    def mail_from
        return @config['mail']['from']
    end

    def mail_to
        return @config['mail']['to']
    end

    def network4
        return ServerPool.new(@config['pools'])
    end

    def network6
        return ServerPool.new(@config['v6-pools'])
    end

    def dns_updater
        return DnsUpdater.new(
            @config['nsupdate']['bin'],
            @config['nsupdate']['keyfile'],
            @config['nsupdate']['server']
        )
    end

end

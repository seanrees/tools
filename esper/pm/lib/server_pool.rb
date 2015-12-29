class ServerPool
    attr_accessor :pool

    # config should be a hash
    # { poolName => [ serverlist ] }
    def initialize(config)
        raise 'config must be hash' unless config.is_a?(Hash)

        @pool = config
    end

    def server_list
        server_set = []
        @pool.each { |name, servers|
            servers.each { |server|
                server_set.push server unless server_set.include? server
            }
        }

        return server_set
    end

    def pools(server_name)
        pools = [];

        @pool.each { |pool_name, servers|
            pools.push(pool_name) if servers.include?(server_name)
        }

        return pools
    end
end

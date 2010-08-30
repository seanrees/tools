#!/usr/local/bin/ruby19
#
# Simple pool management tool for EsperNet
#
# (c) 2010 Sean Rees <sean@rees.us> | <eri@esper.net>
#
# == Usage
#
# pm.rb add name [name2 name3 ...]
# pm.rb delete name [name2 name3 ...]
#
# Examples:
#
# Add dream to its pools:
# pm.rb add dream
#
# Remove triton from its pools:
# pm.rb delete triton
#
# Add dream, triton, and paradox to their pools:
# pm.rb add dream triton paradox
#
# Remove triton and reach from their pools:
# pm.rb delete triton reach
#

require 'logger'
require 'resolv'
require 'yaml'
require 'lib/config.rb'
require 'lib/dns_updater.rb'
require 'lib/server_pool.rb'

def usage
    $stderr.puts "Usage: pm.rb add,delete name1 [name2 name3]"
    exit -1
end

def log_use(argv)
    who = ENV['LOGNAME']

    usage_log = Logger.new('pm.log')
    usage_log.info("'#{argv.join(" ")}' by #{who}")
    usage_log.close
end

def process(command, names)
    if command != 'add' and command != 'delete'
        $stderr.puts "Unknown command: #{command}\n"
        usage
    end

    $log.info "Performing pool update for #{names.join(", ")}"

    names.each { |name|
        addresses = Resolv.getaddresses("#{name}.#{$domain}")

        $log.info "#{name} is #{addresses.join(", ")}"

        ipv4_address = addresses.shift
        ipv6_address = addresses.shift

        pools4 = $network4.pools(name).map { |pool| pool + "." + $domain }
        pools6 = $network6.pools(name).map { |pool| pool + "." + $domain }

        if (command == 'add')
            $nsupdate.add_all(pools4, ipv4_address, 'A', $ttl)
            $nsupdate.add_all(pools6, ipv6_address, 'AAAA', $ttl) unless ipv6_address.nil?
        else
            $nsupdate.delete_all(pools4, ipv4_address, 'A')
            $nsupdate.delete_all(pools6, ipv6_address, 'AAAA') unless ipv6_address.nil?
        end
    }

    $nsupdate.send

    $log.info "Update complete."
end

usage if ARGV.count < 2

$log      = Logger.new(STDOUT)
$log.datetime_format = ""

$config = Config.new('config.yml')
$network4 = $config.network4
$network6 = $config.network6

$ttl      = $config.default_ttl
$domain   = $config.domain

$nsupdate = $config.dns_updater
$nsupdate.log = $log

log_use ARGV

process(ARGV.shift, ARGV)

#!ruby

require 'logger'
require 'yaml'
require 'lib/config.rb'
require 'lib/email_builder.rb'
require 'lib/email_sender.rb'
require 'lib/fixnum_mixins.rb'
require 'lib/server_pool.rb'
require 'lib/monitor/network_monitor.rb'

def timeify(time)
    if time.nil?
        return "(never)"
    else
        now = Time.now
        diff = now.to_i - time.to_i
        part = 0
        unit = ""

        if (diff <= 1.hours)
            part = diff / 1.minutes
            unit = "minute"
        else
            part = diff / 1.hours
            unit = "hour"
        end

        unit += "s" unless part == 1

        return "#{part} #{unit}"
    end
end

def render_time(time)
    time.strftime("%H:%M:%S %Z")
end

$log = Logger.new('multimon.log')
$log.level = Logger::INFO

$config = Config.new('config.yml')
$network4 = $config.network4

$log.info("multimon for #{$config.domain}")
$log.info("servers: #{$network4.server_list.join(", ")}")

email = EmailSender.new($config.mail_server, $config.mail_port)
from = $config.mail_from
to = $config.mail_to

monitor = NetworkMonitor.new($network4.server_list, $config.domain)

monitor.on("stable", Proc.new { |monitor|
    args = { "name" => monitor.name }

    msg = EmailBuilder.build_from_file('mail/server_stable.erb', to, from, "Server Stable: #{monitor.name}", args)
    email.send(from, to, msg)
})

monitor.on("unstable", Proc.new { |monitor|
    last_successful_connect = monitor.last_successful_connect

    first_failed = "#{timeify(monitor.first_failed)} (starting at #{render_time(monitor.first_failed)})"
    last_success= "#{timeify(monitor.last_successful_connect)} ago (#{render_time(monitor.last_successful_connect)})"

    args = { "name" => monitor.name, "fail_count" => monitor.fail_count, "first_failed" => first_failed, "last_successful_connect" => last_success }

    msg = EmailBuilder.build_from_file('mail/server_unstable.erb', to, from, "Server Unstable: #{monitor.name}", args)
    email.send(from, to, msg)
})

monitor.log = $log
monitor.start

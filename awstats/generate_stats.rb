#!/usr/local/bin/ruby19
#
# Simple driver for awstats. Autogenerates statistics.
#
# (c) 2008-2009 Sean Rees <sean@rees.us>
#
# $Id$
#
# == Synopsis
#
# generate_stats.rb: driver for awstats
#
# == Usage
#
# generate_stats.rb
#

require 'parse_vhosts'
require 'fileutils'

AWSTATS="/usr/local/www/awstats/cgi-bin/awstats.pl"
AWSTATS_BUILDSTATICPAGES="/usr/local/www/awstats/tools/awstats_buildstaticpages.pl"

def build_awstats_config(vhost)
  base_config = IO.readlines("awstats.base.conf")

  site_domain = vhost.server_name
  host_aliases = vhost.server_aliases.join(" ")

  log_file = vhost.custom_log.split(/\s/)[2]
  log_file.sub!("%Y", "%YYYY-24")
  log_file.sub!("%m", "%MM-24")
  log_file.sub!("%d", "%DD-24")

  # prepend vhost specific configuration
  base_config.compact!
  base_config.reverse!

  base_config.push("LogFile=\"#{log_file}\"")
  base_config.push("SiteDomain=\"#{site_domain}\"")
  base_config.push("HostAliases=\"#{host_aliases}\"")

  # reverse again and print out
  base_config.reverse!

  file_name = "awstats.#{site_domain}.conf"
  file = File.new(file_name, "w")
  file.write(base_config.join("\n"))

  return true
end

def run_awstats(config, outdir)
  puts("awstats: #{config} to #{outdir}")

  system("perl", AWSTATS_BUILDSTATICPAGES,
    "-config=#{config}",
    "-dir=#{outdir}",
    "-update",
    "-awstatsprog=#{AWSTATS}")
end

def generate_stats
  vhosts = Apache2VirtualHost.load

  vhosts.each do |vhost|
    puts "generating statistics for #{vhost.server_name}"

    # only work on rotatelogs
    if (vhost.custom_log =~ /rotatelogs.*86400/)
      puts "\t server has rotated logs with day-long rotation"

      puts "\t #{vhost.to_s}"

      # build target dir
      outdir = vhost.document_root.split(File::SEPARATOR)
      outdir.pop
      outdir.push("stats")
      outdir = outdir.join(File::SEPARATOR)

      File.umask(0002)

      Dir.mkdir(outdir) unless File.directory?(outdir)

      build_awstats_config(vhost)
      run_awstats(vhost.server_name, outdir)

      FileUtils.link("#{outdir}/awstats.#{vhost.server_name}.html", "#{outdir}/index.html", :force => true)
      FileUtils.chown_R('www', 'users', outdir)
    end
  end
end


generate_stats

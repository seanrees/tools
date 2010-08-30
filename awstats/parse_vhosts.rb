#!/usr/local/bin/ruby
#
# Virtual Host parser.
#
# (c) 2008-2009 Sean Rees <sean@rees.us>
#
# $Id$
#
# == Synopsis
#
# parse_vhosts.rb: simple virtual host parser for Apache
#
#

APACHECTL="/usr/local/sbin/apachectl"

class Apache2VirtualHost
  attr_accessor :ip, :port, :server_admin, :document_root, :server_name, :server_aliases, :error_log, :custom_log, :directory_index

  def initialize
    @server_aliases = Array.new
  end

  def to_s
    return "ip = #{@ip}, port = #{@port}, server_admin = #{@server_admin}, document_root = #{@document_root}, server_name = #{@server_name}, server_aliases = #{@server_aliases.join(", ")}, error_log = #{@error_log}, custom_log = #{@custom_log}, directory_index = #{@directory_index}"
  end

  class << self
    def load
      vhosts = find_vhosts
      objs = []

      find_vhosts.each_pair do |file, hostlist|
        lines = IO.readlines(file)
        obj = nil     # vhost object to populate

        lines.each do |line|
          line.strip!
          tokens = line.split(/\s+/)

          if line =~ /\<VirtualHost/
            obj = Apache2VirtualHost.new

            hostport = tokens[1].split(/[:>]/)
            obj.ip = hostport[0]
            obj.port = hostport[1]
          elsif line =~ /ServerAdmin/
            obj.server_admin = tokens[1]
          elsif line =~ /DocumentRoot/
            obj.document_root = tokens[1]
          elsif line =~ /ServerName/
            obj.server_name = tokens[1]
          elsif line =~ /ServerAlias/
            obj.server_aliases.push(tokens[1])
          elsif line =~ /DirectoryIndex/
            obj.directory_index = tokens[1]
          elsif line =~ /ErrorLog/
            obj.error_log = tokens[1..-1].join(" ")
          elsif line =~ /CustomLog/
            obj.custom_log = tokens[1..-1].join(" ")
          elsif line =~ /<\/VirtualHost/
            # we're done!
            objs.push(obj)
            obj = nil
          end
        end
      end

      return objs
    end

    private
    def find_vhosts
      command = APACHECTL + " -t -D DUMP_VHOSTS 2>&1"
      files = Hash.new

      # determine files to read
      lines = IO.popen(command).readlines
      lines.each do |line|
        tokens = line.split(/\s+/)
        vhost = nil

        if (line =~ /\s+port \d+ namevhost/)
          vhost = tokens[4]
          file = parse_file(tokens[5])
        end

        unless vhost.nil?
          files[file] = Array.new if files[file].nil?

          files[file].push(vhost)
        end
      end

      return files
    end

    def parse_file(file)
      # pulls foobarbaz out of (foobarbaz:3)
      md = file.match(/\((.*):.*\)/)

      return md.nil? ? nil : md[1]
    end
  end
end

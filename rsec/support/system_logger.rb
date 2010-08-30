# Ruby IRC server
#
# $Id$

require 'logger'

class SystemLogger
  @@loggers = Array.new
  @@instances = Hash.new

  class << self
    def get(name)
      @@instances[name] = SystemLogger.new(name) unless @@instances.has_key?(name)

      return @@instances[name]
    end

    def add(logger)
      @@loggers.push(logger)
    end
  end

  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def log(severity, message)
    for logger in @@loggers
      logger.log(severity, message, "#{@name} [#{Thread.current["name"]}]")
    end
  end

  def debug(message)
    log(Logger::DEBUG, message)
  end

  def info(message)
    log(Logger::INFO, message)
  end

  def warn(message)
    log(Logger::WARN, message)
  end

  def error(message)
    log(Logger::ERROR, message)
  end

  def fatal(message)
    log(Logger::FATAL, message)
  end
end

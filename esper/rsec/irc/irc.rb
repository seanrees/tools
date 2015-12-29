# Ruby IRC server
#
# $Id$

module Irc
  DEFAULT_PORT = 6667

  def timestamp
    return Time.now.to_i
  end
end

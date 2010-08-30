require 'net/smtp'

class EmailSender
    attr_accessor :server, :port

    def initialize(server = 'localhost', port = 25)
        @server = server
        @port = port
    end

    def send(from, to, body)
        Net::SMTP.start(@server, @port) { |smtp| smtp.send_message body, from, to }
    end

end

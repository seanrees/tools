class IrcConnection
    attr_accessor :in, :out

    def open
        raise "use a subclass"
    end

    def close
        raise "use a subclass"
    end
end

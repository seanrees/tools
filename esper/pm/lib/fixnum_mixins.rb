module TimeInSeconds
    def days
        hours * 24
    end

    def hours
        minutes * 60
    end

    def minutes
        seconds * 60
    end

    def seconds
        self
    end
end

class Fixnum
    include TimeInSeconds
end

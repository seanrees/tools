require 'erb'

class Hash
    def to_binding(object = Object.new)
        object.instance_eval("def binding_for(#{keys.join(",")}) binding end")
        object.binding_for(*values)
    end
end

class EmailBuilder
    def EmailBuilder.build_from_file(template_file, to, from, subject, args)
        template = ""
        File.open(template_file) { |io|
            template = io.read
        }

        EmailBuilder.build(template, to, from, subject, args)
    end

    def EmailBuilder.build(template, to, from, subject, args)
        template = process_template(template, args)

        build_headers(to, from, subject) + "\n\n" + template
    end

    def EmailBuilder.build_headers(to, from, subject)
        headers = "To: #{to}\n" +
                  "From: #{from}\n" +
                  "Subject: #{subject}"
    end

    def EmailBuilder.process_template(template, args)
        raise "args must be a hash or nil" unless args.nil? or args.is_a?(Hash)

        args = Hash.new if args.nil?

        ERB.new(template).result(args.to_binding)
    end
end

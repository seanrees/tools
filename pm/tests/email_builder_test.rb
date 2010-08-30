require 'test/unit'
require 'lib/email_builder.rb'

class EmailBuilderTest < Test::Unit::TestCase
    def test_build_headers
        headers = EmailBuilder.build_headers('to <to@addr>', 'from <from@addr>', 'this is a subject')

        assert_equal("To: to <to@addr>\nFrom: from <from@addr>\nSubject: this is a subject", headers)
    end

    def test_process_template
        template = "<%= x %> <%= y %>"
        args = { "x" => 10, "y" => 100 }

        result = EmailBuilder.process_template(template, args)
        assert_equal("10 100", result)

        # references variables that don't exist
        assert_raise(NameError) { EmailBuilder.process_template(template, nil) }

        template = ""
        result = EmailBuilder.process_template(template, args)
        assert_equal("", result)

        assert_equal("", EmailBuilder.process_template("", nil))

        assert_raise(RuntimeError) { EmailBuilder.process_template("", "") }
        assert_raise(RuntimeError) { EmailBuilder.process_template("", []) }
    end

    # more of an integration test
    def test_build
        template = "<%= x %> <%= y %>"
        args = { "x" => 10, "y" => 100 }

        result = EmailBuilder.build(template, 'to', 'from', 'subject', args)

        assert_equal("To: to\nFrom: from\nSubject: subject\n\n10 100", result)
    end
end

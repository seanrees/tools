require 'test/unit'
require 'lib/fixnum_mixins.rb'

class FixnumMixinsTest < Test::Unit::TestCase
    def test_days
        assert_equal(0.days, 0)
        assert_equal(1.days, 86400)
        assert_equal(2.days, 172800)
        assert_equal(10.days, 864000)
    end

    def test_hours
        assert_equal(0.hours, 0)
        assert_equal(1.hours, 3600)
        assert_equal(2.hours, 7200)
        assert_equal(10.hours, 36000)
    end

    def test_minutes
        assert_equal(0.minutes, 0)
        assert_equal(1.minutes, 60)
        assert_equal(2.minutes, 120)
        assert_equal(10.minutes, 600)
    end

    def test_seconds
        assert_equal(0.seconds, 0)
        assert_equal(1.seconds, 1)
        assert_equal(2.seconds, 2)
        assert_equal(10.seconds, 10)
    end
end

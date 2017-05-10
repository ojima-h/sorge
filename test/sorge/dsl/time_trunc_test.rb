require 'test_helper'

module Sorge
  class DSL
    class TimeTruncTest < SorgeTest
      def test_default
        time_trunc = TimeTrunc::Default.new

        assert_equal 11, time_trunc.call(11)
        assert_equal 12, time_trunc.call(12)
        assert_equal 13, time_trunc.call(13)
      end

      def test_default_turnc
        time_trunc = TimeTrunc::Default.new(3)

        assert_equal 9, time_trunc.call(11)
        assert_equal 12, time_trunc.call(12)
        assert_equal 12, time_trunc.call(13)
      end

      def test_day
        time_trunc = TimeTrunc::Day.new

        assert_equal Date.today.to_time.to_i, time_trunc.call(Time.now)
      end

      def test_week
        time_trunc = TimeTrunc::Week.new(3)
        dt = ->(y, m, d) { Date.new(y, m, d).to_time.to_i }

        assert_equal dt[2017, 3, 29], time_trunc.call(dt[2017, 4, 3])
        assert_equal dt[2017, 4, 5], time_trunc.call(dt[2017, 4, 5])
        assert_equal dt[2017, 4, 5], time_trunc.call(dt[2017, 4, 7])
      end

      def test_month
        time_trunc = TimeTrunc::Month.new(15)
        dt = ->(y, m, d) { Date.new(y, m, d).to_time.to_i }

        assert_equal dt[2017, 3, 15], time_trunc.call(dt[2017, 4, 14])
        assert_equal dt[2017, 4, 15], time_trunc.call(dt[2017, 4, 15])
        assert_equal dt[2017, 4, 15], time_trunc.call(dt[2017, 4, 16])
      end
    end
  end
end

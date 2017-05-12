require 'test_helper'

module Sorge
  class DSL
    class TimeTruncTest < SorgeTest
      def test_default
        time_trunc = TimeTrunc::Default.new

        assert_equal Time.at(now + 1), time_trunc.call(now + 1)
        assert_equal Time.at(now + 2), time_trunc.call(now + 2)
        assert_equal Time.at(now + 3), time_trunc.call(now + 3)
      end

      def test_default_turnc
        time_trunc = TimeTrunc::Default.new(3)

        assert_equal Time.at((now.to_i + 1) / 3 * 3), time_trunc.call(now + 1)
        assert_equal Time.at((now.to_i + 2) / 3 * 3), time_trunc.call(now + 2)
        assert_equal Time.at((now.to_i + 3) / 3 * 3), time_trunc.call(now + 3)
      end

      def test_day
        time_trunc = TimeTrunc::Day.new

        assert_equal now.to_date.to_time, time_trunc.call(now)
      end

      def test_week
        time_trunc = TimeTrunc::Week.new(3)
        dt = ->(y, m, d) { Date.new(y, m, d).to_time }

        assert_equal dt[2017, 3, 29], time_trunc.call(dt[2017, 4, 3])
        assert_equal dt[2017, 4, 5], time_trunc.call(dt[2017, 4, 5])
        assert_equal dt[2017, 4, 5], time_trunc.call(dt[2017, 4, 7])
      end

      def test_month
        time_trunc = TimeTrunc::Month.new(15)
        dt = ->(y, m, d) { Date.new(y, m, d).to_time }

        assert_equal dt[2017, 3, 15], time_trunc.call(dt[2017, 4, 14])
        assert_equal dt[2017, 4, 15], time_trunc.call(dt[2017, 4, 15])
        assert_equal dt[2017, 4, 15], time_trunc.call(dt[2017, 4, 16])
      end
    end
  end
end

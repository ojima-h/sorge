require 'test_helper'

module Sorge
  class DSL
    class CoreTimeTest < SorgeTest
      def test_default
        t1 = Sorge.tasks['test_trigger:t1']

        assert_equal t1.trigger, Trigger.default
        assert_equal t1.time_trunc, TimeTrunc.default
      end

      def test_time_trunc
        t2 = Sorge.tasks['test_trigger:t2']

        assert_kind_of TimeTrunc::Default, t2.time_trunc
        assert_equal 10, t2.time_trunc.instance_eval { @sec }
      end

      def test_declair
        t3 = Sorge.tasks['test_trigger:t3']

        assert_kind_of TimeTrunc::Week, t3.time_trunc
        assert_equal 3, t3.time_trunc.instance_eval { @wday }

        assert_kind_of Trigger::Periodic, t3.trigger
        assert_equal 3, t3.trigger.instance_eval { @period }
      end

      def test_with_block
        t4 = Sorge.tasks['test_trigger:t4']

        assert_kind_of Proc, t4.time_trunc
        assert_equal 9, t4.time_trunc.call(10)

        assert_kind_of Trigger::Custom, t4.trigger
        assert_equal [[0], []], t4.trigger.call([0], nil)
      end

      def test_with_lambda
        t5 = Sorge.tasks['test_trigger:t5']

        assert_kind_of Proc, t5.time_trunc
        assert_equal 9, t5.time_trunc.call(10)

        assert_kind_of Trigger::Custom, t5.trigger
        assert_equal [[0], []], t5.trigger.call([0], nil)
      end
    end
  end
end

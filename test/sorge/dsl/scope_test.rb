require 'test_helper'

module Sorge
  class DSL
    class ScopeTest < SorgeTest
      def test_ok
        Scope.with('foo:bar') do
          Scope.with(:baz) do
            assert_equal :baz, Scope.current.name
            assert_equal 'foo:bar:baz', Scope.current.path
            assert_equal ['foo:bar', :baz], Scope.current.map(&:name)
            assert_equal 'foo:bar:baz:qux', Scope.current.join(:qux)
          end
          assert_equal 'foo:bar', Scope.current.name
        end

        assert_equal '', Scope.current.path
        assert_empty Scope.current.to_a
      end
    end
  end
end

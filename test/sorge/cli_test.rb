require 'test_helper'

module Sorge
  class CLITest < SorgeTest
    def test_run
      assert runcli('run', 't1')
      refute runcli('run', 'test_failure:fatal')
    end
  end
end

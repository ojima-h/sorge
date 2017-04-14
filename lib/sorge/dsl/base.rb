module Sorge
  class DSL
    # Common methods for Task and Mixin
    module Base
      class << self
        def create(dsl, name)
          Module.new do
            include Base
            init(dsl, name)
          end
        end
      end

      include Core
      include CoreInclude
      include CoreHook
      include CoreSettings
      include CoreUpstreams
      include CoreWindow
    end
  end
end

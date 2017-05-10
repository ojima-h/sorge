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
      include CoreEmit
      include CoreHook
      include CoreSettings
      include CoreTime
      include CoreUpstreams
      include CoreUse
      include CoreWindow
    end
  end
end

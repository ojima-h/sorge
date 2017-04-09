module Sorge
  class DSL
    module CoreWindow
      include Core

      class_methods do
        def init(name, dsl)
          super
          @window_spec = nil
          @window_handler = nil
        end

        def window(type = nil, options = {}, &block)
          @window_spec =
            if type.nil?
              [:null]
            elsif type.is_a?(Proc) || block_given?
              [:custom, {}, (type || block)]
            elsif type.is_a? Integer
              [:tumbling, size: type, **options]
            else
              [type, options, block]
            end
        end

        def window_spec
          return [:null] unless initialized?
          @window_spec || super_mixin.window_spec
        end

        def window_handler
          @window_handler ||=
            begin
              type, options, block = window_spec
              @window_handler = Window[type].new(self, options || {}, &block)
            end
        end
      end
    end
  end
end

module Sorge
  class DSL
    module CoreWindow
      include Core

      class_methods do
        def init(name, dsl)
          super
          @window_handler = nil
        end

        def window(type = nil, options = {}, &block)
          @window_handler =
            if type.nil?
              Window.null
            elsif type.is_a?(Proc) || block_given?
              Window[:custom].new(self, &(type || block))
            elsif type.is_a? Integer
              Window[:tumbling].new(self, size: type, **options)
            else
              Window[type].new(self, options, &block)
            end
        end

        def window_handler
          return Window.null unless initialized?
          @window_handler || super_mixin.window_handler
        end
      end
    end
  end
end

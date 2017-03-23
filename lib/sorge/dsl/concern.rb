module Sorge
  class DSL
    module Concern
      def class_methods(&block)
        @class_methods ||= Module.new

        if block_given?
          @class_methods.module_eval(&block)
          extend @class_methods
        end

        @class_methods
      end

      def included(obj)
        obj.extend Concern
        my_class_methods = class_methods
        obj.class_methods { include my_class_methods }
      end
    end
  end
end

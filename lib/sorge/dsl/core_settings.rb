module Sorge
  class DSL
    module CoreSettings
      extend Concern

      class_methods do
        # Declared setting.
        #
        #     play :foo do
        #       set :first_name, 'Taro'
        #       set :family_name, 'Yamada'
        #       set :full_name, -> { first_name + ' ' + family_name }
        #
        #       action do
        #         full_name #=> 'Taro Yamada'
        #       end
        #     end
        #
        # Settings are defiend as an intance methods of the task.
        def set(name, value = nil, &block)
          var = :"@#{name}"

          define_method(name) do
            unless instance_variable_defined?(var)
              val = eval_setting(value, &block)
              instance_variable_set(var, val)
            end
            instance_variable_get(var)
          end
        end
      end

      private

      def eval_setting(value = nil, &block)
        return instance_exec(&value) if value.is_a? Proc
        return value unless value.nil?
        return instance_exec(&block) if block_given?
        true
      end
    end
  end
end

module Sorge
  class DSL
    module CoreSettings
      include Core

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
        def set(name, *args, &block)
          var = :"@#{name}"

          define_method(name) do
            unless instance_variable_defined?(var)
              val = Util.assume_proc(args.fetch(0, block || true))
              instance_variable_set(var, instance_exec(&val))
            end
            instance_variable_get(var)
          end
        end
      end
    end
  end
end

module Sorge
  class DSL
    # Common methods for Task and Mixin
    module Core
      attr_reader :name

      def init(name, dsl)
        @name = name
        @dsl = dsl
      end

      def enhance(&block)
        class_eval(&block)
      end

      def upstreams
        @upstreams ||= {}
      end

      def successors
        @dsl.task_graph.direct_successors(self)
      end

      # Declare upstreams.
      #
      #   task :foo do
      #     upstream :bar
      #   end
      def upstream(name, *args)
        upstreams[@dsl.task_manager[name, Scope.current]] = args
      end

      # All actions defined.
      #
      #     task :foo do
      #       setup { 'this block is added to actions[:setup]' }
      #       after { ... }
      #
      #       actions #=> { setup: [#<Proc ...>], after: [#<Proc ...>] }
      #     end
      def actions
        @actions ||= Hash.new { |hash, key| hash[key] = [] }
      end

      # Define helper methods.
      #
      #     task :foo do
      #       helpers do
      #         def country
      #           :jp
      #         end
      #       end
      #
      #       country #=> :jp
      #     end
      #
      # If no block given, it returns the helper module.
      #
      # @return [Module] helpers module
      def helpers(*extensions, &block)
        @helpers ||= Module.new
        @helpers.module_eval { include(*extensions) } if extensions.any?
        @helpers.module_eval(&block) if block_given?
        @helpers
      end

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

      #
      # Setting Helpers
      #

      # @!visibility private
      def self.def_setting_helper(name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}(val = nil, &block)
          set :#{name}, val, &block
        end
        RUBY
      end

      # @!method worker(val = nil, &block)
      #   Set :worker name.
      #
      #       play :foo do
      #         worker :my_worker
      #         action { ... }
      #       end
      #
      #   This is short-hand style of `set :worker, :my_worker`
      def_setting_helper :worker

      #
      # Actions
      #

      # @!visibility :private
      def self.define_action(name)
        define_method(name) do |&block|
          actions[name] << block
        end
      end

      # @!method setup(&block)
      #   Register _setup_ action.
      #
      #   Setup action is called before #run.
      #   All prerequisites should be declared inside the setup blocks.
      #
      #       play :foo do
      #         setup do
      #           puts 'Setup!'
      #         end
      #
      #         action do
      #           puts 'Running!'
      #         end
      #       end
      #
      #       $ sorge foo
      #       ... (:bar is executed)
      #       Setup!
      #       Running!
      define_action :setup

      # @!method action(&block)
      #   Register main action.
      #
      #       play :foo do
      #         action { ... }
      #       end
      #
      #   `action` block is not executed in dryrun mode.
      define_action :action

      # @!method safe_action(&block)
      #   Register safe action.
      #   `safe_action` is similar to `action`, but this block is executed
      #   in dryrun mode.
      #
      #   You should guard dangerous operations in a safe_action block.
      #   This is useful to preview detail behavior of the task.
      define_action :safe_action

      # @!method after(&block)
      #   Register _after_ action.
      #
      #   After action is called after the main actions.
      #
      #       play :foo do
      #         action do
      #           ...
      #         end
      #
      #         after do |error|
      #           next if error.nil?
      #           $syserr.puts "[ERROR] #{task.name} failed:"
      #           $syserr.puts "[ERROR]   #{error}"
      #         end
      #       end
      #
      #   `after` block is not executed in dryrun mode.
      #
      #   @yieldparam error [StandardError, nil] if run method failed,
      #     otherwise nil.
      define_action :after

      # Include mixins.
      #
      # All methods, actions and settings are inherited.
      #
      #     mixin :foo do
      #       param :country
      #     end
      #
      #     play :bar do
      #       include :bar
      #       params_spec #=> { country: {} }
      #     end
      #
      # When Module objects are given, it includes them as usual.
      #
      # @param mod [Array<Symbol, String, Module>] mixin name or module.
      def include(*mod)
        ms = mod.map { |m| resolve_mixin(m) }
        super(*ms)
      end
      private :include

      # @!visibility private
      def resolve_mixin(mod)
        return mod if mod.is_a? Module

        mixin = @dsl.task_manager[mod, Scope.current]
        raise "#{mod} is not a mixin" unless mixin < Mixin

        mixin
      end
      private :resolve_mixin

      # Return a list of Mixin objects included.
      def mixins
        ancestors.select { |o| o.is_a? Core }
      end
    end
  end
end

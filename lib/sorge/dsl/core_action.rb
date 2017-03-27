module Sorge
  class DSL
    module CoreAction
      extend Concern

      class_methods do
        def init_actions
          @actions = Hash.new { |hash, key| hash[key] = [] }
        end

        def each_action(tag, &block)
          return unless initialized?

          super_mixin.each_action(tag, &block)
          @actions[tag].each { |b| yield b }
        end

        # @!visibility :private
        def self.define_action(name)
          define_method(name) do |&block|
            @actions[name] << block
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
      end

      def setup
        call_action(:setup)
      end

      def execute
        call_action(:action)
      end

      private

      # Call each actions
      # @param tag [Symbol] action name
      # @param args [Array] arguments
      def call_action(tag, *args)
        self.class.each_action(tag) do |block|
          instance_exec(*args, &block)
        end
      end
    end
  end
end

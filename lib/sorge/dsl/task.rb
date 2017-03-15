module Sorge
  class DSL
    class Task
      extend Core
      extend Forwardable

      def self.create(name, dsl)
        Class.new(self) do
          init(dsl, name, Task)

          include dsl.global_mixin
          extend helpers
        end
      end

      def initialize(params = {})
        @params = params.dup
      end
      attr_reader :params

      def execute
        call_action(:action)
      end

      def to_s
        task.name + ' ' + params.to_json
      end

      private

      # Call each actions
      # @param tag [Symbol] action name
      # @param args [Array] arguments
      def call_action(tag, *args)
        self.class.mixins.reverse.each do |mixin|
          mixin.actions[tag].each do |block|
            instance_exec(*args, &block)
          end
        end
      end

      # @!visibility private
      def eval_setting(value = nil, &block)
        return instance_exec(&value) if value.is_a? Proc
        return value unless value.nil?
        return instance_exec(&block) if block_given?
        true
      end

      #
      # Helper methods
      #
      def task
        self.class
      end

      def logger
        Sorge.logger
      end

      def dryrun?
        @dsl.options.dryrun
      end
    end
  end
end

module Sorge
  class DSL
    class Task
      extend Core

      def self.create(name, dsl)
        Class.new(self) do
          init(name, dsl)

          include dsl.global_mixin
          extend helpers
        end
      end

      def self.inspect
        "#<Sorge::DSL::Task #{name}>"
      end

      def self.all_upstreams
        ret = {}
        mixins.reverse.each { |mixin| ret.update(mixin.upstreams) }
        ret
      end

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
      private :eval_setting

      def logger
        @dsl.logger
      end

      def dryrun?
        @dsl.options.dryrun
      end
    end
  end
end

module Sorge
  class DSL
    module CoreHook
      include Core

      class_methods do
        def init(app, name)
          super
          @hooks = Hash.new { |hash, key| hash[key] = [] }
        end

        def each_hook(tag, &block)
          return unless initialized?

          super_mixin.each_hook(tag, &block)
          @hooks[tag].each { |b| yield b }
        end

        # @!visibility :private
        def self.define_hook(name)
          define_method(name) do |&block|
            @hooks[name] << block
          end
        end

        # @!method setup(&block)
        define_hook :setup

        # @!method before(&block)
        define_hook :before

        # @!method successed(&block)
        define_hook :successed

        # @!method failed(error, &block)
        define_hook :failed

        # @!method after(&block)
        define_hook :after
      end

      private

      # Call each hooks
      # @param tag [Symbol] hook name
      # @param args [Array] arguments
      def call_hook(tag, *args)
        self.class.each_hook(tag) do |block|
          instance_exec(*args, &block)
        end
      end
    end
  end
end

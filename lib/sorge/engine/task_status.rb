module Sorge
  class Engine
    TaskStatus = Struct.new(
      :state,
      :trigger_state,
      :pending,
      :running,
      :finished,
      :position
    ) do
      def initialize(*args)
        super
        self.state ||= {}
        self.trigger_state ||= {}
        self.pending ||= []
        self.running ||= []
        self.finished ||= []
        self.position ||= 0
      end

      def freeze!
        values.each(&:freeze)
        freeze
      end

      def next?
        !finished.empty?
      end
    end
  end
end

module Sorge
  class DSL
    module CoreEmit
      def emitted
        @emitted ||= []
      end

      def emit(time)
        emitted << Util::Time(time)
      end
    end
  end
end

module Sorge
  class DSL
    module CoreEmit
      def emitted
        @emitted ||= []
      end

      def emit(*times)
        times.each do |time|
          emitted << Util::Time(time)
        end
      end
    end
  end
end

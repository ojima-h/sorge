module Sorge
  class DSL
    module CoreEmit
      def emitted
        @emitted ||= []
      end

      def emit(time)
        tm = case time
             when Date then time.to_time.to_i
             when Time then time.to_i
             when String then Time.parse(time).to_i
             else time.to_i
             end
        emitted << tm
      end
    end
  end
end

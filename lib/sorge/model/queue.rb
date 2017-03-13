module Sorge
  class Model
    class Queue
      STATUS_PENDING = 0
      STATUS_RUNNING = 1

      FETCH_SIZE = 100
      FETCH_INTERVAL = 1

      def initialize(table)
        @table = table
        @mtx = Mutex.new
        @buffer = []
      end

      def get
        @mtx.synchronize do
          loop do
            fetch if @buffer.empty?
            msg = @buffer.shift
            break msg if mark_running(msg.id)
          end
        end
      end

      def post(hash)
        @table.create(status: STATUS_PENDING, **hash)
      end

      def delete(id)
        @table.where(id: id).delete
      end

      private

      def fetch
        loop do
          @buffer = @table.where(status: STATUS_PENDING)
                          .order(:created_at)
                          .limit(FETCH_SIZE).to_a
          break unless @buffer.empty?
          sleep FETCH_INTERVAL
        end
      end

      def mark_running(id)
        ret = @table.where(id: id, status: STATUS_PENDING)
                    .update(status: STATUS_RUNNING)
        ret > 0
      end
    end
  end
end

module Sorge
  class Engine
    class Savepoint
      def initialize(engine)
        @engine = engine
        @path = engine.config.get('core.savepoint_path')
        @interval = engine.config.get('core.savepoint_interval')

        @latest = nil
        @started = Concurrent::AtomicBoolean.new
        @worker = nil
      end
      attr_reader :latest

      def latest_file_path
        File.join(@path, 'latest')
      end

      def stop
        @worker.shutdown if @worker
      end

      def start
        return if @interval <= 0
        return unless @started.make_true

        @worker = Concurrent::TimerTask.new(
          execution_interval: interval,
          timeout_interval: 60
        ) do
          @engine.event_queue.submit(:savepoint)
        end.execute
      end

      def update
        file_path = @engine.synchronize { write }
        swap(file_path)
        Sorge.logger.info("savepoint updated: #{file_path}")
      ensure
        try_write(latest_file_path, latest)
      end

      # update savepoint everytime when event_queue consumes a message.
      def fine_update
        update if @interval < 0
      end

      def read(file_path)
        YAML.load_file(file_path)
      end

      private

      def data
        {
          queue: @engine.event_queue.queue,
          running: @engine.task_runner.running,
          states: @engine.task_states
        }
      end

      def write
        id = 'savepoint-' + Util.generate_id
        file_path = File.join(@path, id + '.yml')
        FileUtils.makedirs(File.dirname(file_path))
        File.write(file_path, YAML.dump(data))
        file_path
      end

      def swap(file_path)
        f = @latest
        @latest = file_path
        try_delete(f) if f
      end

      def try_delete(file_path)
        File.delete(file_path)
      rescue
        nil # savepoint file may be deleted while test running
      end

      def try_write(file_path, body)
        File.write(file_path, body)
      rescue
        nil # savepoint file may be deleted while test running
      end
    end
  end
end

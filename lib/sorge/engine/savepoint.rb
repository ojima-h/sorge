module Sorge
  class Engine
    class Savepoint
      def initialize(engine)
        @engine = engine
        @path = engine.config.get('savepoint.path')
        @interval = engine.config.get('savepoint.interval')

        @files = []
        @started = Concurrent::AtomicBoolean.new
        @worker = nil
      end

      def latest
        @files.last
      end

      def start
        return if @interval <= 0
        return unless @started.make_true

        @worker = Concurrent::TimerTask.new(
          execution_interval: interval,
          timeout_interval: 60
        ) do
          @engine.event_queue.peek(:savepoint)
        end
      end

      def dump
        Engine.synchronize do
          write(
            queue: @engine.event_queue.queue,
            running: @engine.task_runner.running,
            states: @engine.task_states
          )
          clean
        end
      end

      def jobflow_file_path(id)
        File.join(@path, 'jobflows', id + '.yml')
      end

      def put_jobflow(id, jobs)
        file_path = jobflow_file_path(id)
        FileUtils.makedirs(File.dirname(file_path))
        File.write(file_path, YAML.dump(jobs))
      end

      def get_jobflow(id)
        file_path = jobflow_file_path(id)
        YAML.load_file(file_path)
      end

      def delete_jobflow(id)
        file_path = jobflow_file_path(id)
        return unless File.file?(file_path)
        File.delete(file_path)
      end

      private

      def write(data)
        id = 'savepoint-' + Util.generate_id
        file_path = File.join(@path, id + '.yml')
        FileUtils.makedirs(File.dirname(file_path))
        File.write(file_path, YAML.dump(data))
        Sorge.logger.info("savepoint updated: #{file_path}")
        @files << file_path
      end

      def clean
        File.delete(*@files[0..-2])
      end
    end
  end
end

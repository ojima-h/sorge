module Sorge
  class Engine
    class Savepoint
      def initialize(engine)
        @engine = engine
        @path = engine.config.savepoint_path
        @interval = engine.config.savepoint_interval
        @last_saved = nil
        @latest = nil
      end
      attr_reader :latest

      def latest_file_path
        File.join(@path, 'latest')
      end

      def save(data)
        return unless should_save?
        save!(data)
      end

      def save!(data)
        file_path = write(data)
        @last_saved = Time.now

        swap(file_path)
        Sorge.logger.info("savepoint updated: #{file_path}")
      end

      def read(file_path)
        file_path = File.read(latest_file_path) if file_path == 'latest'
        Sorge.logger.info("savepoint restored: #{file_path}")
        YAML.load_file(file_path)
      end

      private

      def should_save?
        return true if @last_saved.nil?
        Time.now >= @last_saved + @interval
      end

      def write(data)
        id = 'savepoint-' + Util.generate_id
        file_path = File.join(@path, id + '.yml')
        FileUtils.makedirs(File.dirname(file_path))
        File.write(file_path, YAML.dump(data))
        file_path
      end

      def swap(file_path)
        f = @latest
        @latest = file_path
        save_latest

        try_delete(f) if f
      end

      def try_delete(file_path)
        File.delete(file_path)
      rescue
        nil # savepoint file may be deleted while test running
      end

      def save_latest
        File.write(latest_file_path, latest)
      rescue
        nil # savepoint file may be deleted while test running
      end
    end
  end
end

module Sorge
  class Engine
    class Savepoint
      def initialize(engine)
        @engine = engine
        @latest = nil
      end
      attr_reader :latest

      def latest_file_path
        File.join(@engine.config.savepoint_path, 'latest')
      end

      def save(data)
        return if @engine.app.dryrun? || !@engine.app.savepoint?

        file_path = write(data)
        swap(file_path)
        Sorge.logger.debug("savepoint updated: #{file_path}")
      end

      def read(file_path)
        file_path = read_latest if file_path == 'latest'
        Sorge.logger.info("savepoint restored: #{file_path}")
        YAML.load_file(file_path)
      end

      private

      def write(data)
        id = 'savepoint-' + Util.generate_id
        file_path = File.join(@engine.config.savepoint_path, id + '.yml')
        FileUtils.makedirs(File.dirname(file_path))
        File.write(file_path, YAML.dump(data))
        file_path
      end

      def swap(file_path)
        f = @latest
        @latest = file_path
        write_latest(@latest)

        File.delete(f) if f
      end

      def read_latest
        open(latest_file_path) { |f| f.gets.strip }
      end

      def write_latest(latest)
        File.write(latest_file_path, latest)
      end
    end
  end
end

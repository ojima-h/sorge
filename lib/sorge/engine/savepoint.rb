module Sorge
  class Engine
    class Savepoint
      def initialize(engine)
        @engine = engine
      end

      def path
        @path ||= @engine.application.config.get('savepoint.path')
      end

      def jobflow_file_path(id)
        File.join(path, 'jobflows', id + '.yml')
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
    end
  end
end

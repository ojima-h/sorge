require 'sequel'

module Sorge
  class CLI
    class Migrate
      def initialize(app, option)
        @app = app
        @option = option
      end

      def run
        db = @app.model.connect(check_current: false)
        dir = Sorge::Model::MIGRATIONS_PATH

        if Sequel::Migrator.is_current?(db, dir)
          puts 'Schema is latest.'
          return
        end

        puts 'Start migration...'
        Sequel::Migrator.run(db, dir)
        puts 'Done'
      end
    end
  end
end

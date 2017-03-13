require 'sequel'

module Sorge
  class Model
    Sequel.extension :migration

    MIGRATIONS_PATH = File.expand_path('../../../migrations', __FILE__)

    DEFAULT_CONIFG = {
      adapter: 'sqlite',
      database: './sorge.db',
      max_connections: 1
    }.freeze

    def initialize(app)
      @app = app
    end
    attr_reader :app

    def connect(check_current: true)
      conn = Sequel.connect(config)
      Sequel::Migrator.check_current(conn, MIGRATIONS_PATH) if check_current
      conn
    rescue Sequel::Migrator::NotCurrentError
      raise Error, 'current schema is out of date'
    end

    def database
      @database ||= connect
    end

    def config
      app.config.fetch(:database) { DEFAULT_CONIFG }
    end

    def self.define_model(table_name, &block)
      Class.new(Sequel::Model) do
        @__sorge_table_name = table_name

        def self.connect(database)
          Class.new(self.Model(database[@__sorge_table_name])) do
            send(:connected) if respond_to?(:connected)
          end
        end

        class_eval(&block)
      end
    end

    def event_queue
      @event_queue ||= EventQueue.connect(database)
    end
  end
end

require 'sorge/model/queue'
require 'sorge/model/event_queue'

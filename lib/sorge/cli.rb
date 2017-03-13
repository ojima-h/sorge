require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :config_file, aliases: '-C', desc: 'config file path'

    def initialize(*args)
      super(*args)
      @app = Sorge::Application.new(config_file: options[:config_file])
    end

    desc 'init', 'Create new abid project'
    def init
      migrate
    end

    desc 'upgrade', 'Upgrade current abid project'
    def upgrade
      migrate
    end

    private

    def migrate
      require 'sorge/cli/migrate'
      Migrate.new(@app, options).run
    end
  end
end

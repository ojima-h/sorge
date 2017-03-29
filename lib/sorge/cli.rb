require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :config_file, aliases: '-C', desc: 'config file path'
    class_option :sorgefile, aliases: '-f', desc: 'Sorgefile path'

    def initialize(*args)
      super
      @app = Sorge::Application.new(
        config_file: options[:config_file],
        sorgefile: options[:sorgefile]
      )
    end

    desc 'init', 'Create new sorge project'
    def init
      migrate
    end

    desc 'upgrade', 'Upgrade current sorge project'
    def upgrade
      migrate
    end

    desc 'run TASK [KEY=VAL]...', 'Run task'
    def _run(task, *args)
      require 'sorge/cli/run'
      Run.new(@app, task, args, options).run
    end
    map run: :_run

    desc 'server', 'Start Sorge server'
    def server
      require 'sorge/server'
      Sorge::Server.build(@app).run!
    end

    private

    def migrate
      require 'sorge/cli/migrate'
      Migrate.new(@app, options).run
    end
  end
end

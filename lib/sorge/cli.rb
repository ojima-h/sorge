require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :config_file, aliases: '-C', desc: 'config file path'

    def self.app_options
      option :sorgefile, aliases: '-f', desc: 'Sorgefile path'
    end

    desc 'run TASK [KEY=VAL]...', 'Run task'
    app_options
    def _run(task, time, *args)
      require 'sorge/cli/run'
      Run.new(app, task, time, args, options).run
    end
    map run: :_run

    desc 'server', 'Start Sorge server'
    app_options
    def server
      require 'sorge/server'
      Sorge::Server.build(app).run!
    end

    desc 'submit', 'Submit a job to server'
    def submit(task, *args)
      require 'sorge/cli/submit'
      Submit.new(config, task, args, options).run
    end

    private

    def sorge_options
      @sorge_options ||= Util.symbolize_keys(options.to_hash)
    end

    def app
      @app ||= Application.new(sorge_options)
    end

    def config
      @config ||= Config.new(sorge_options)
    end
  end
end

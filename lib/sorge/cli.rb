require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :config_file, aliases: '-C', desc: 'config file path'
    class_option :environment, aliases: '-e', desc: 'environment'

    def self.app_options
      option :sorgefile, aliases: '-f', desc: 'Sorgefile path'
    end

    def self.local_options
      option :dryrun, aliases: '-n', type: :boolean, default: false,
                      desc: 'dryrun'
    end

    desc 'run TASK TIME [KEY=VAL]...', 'Run task'
    app_options
    local_options
    def _run(task, time, *args)
      require 'sorge/cli/run'
      Run.new(app, task, time, args, options).run
    end
    map run: :_run

    desc 'exec TASK TIME [KEY=VAL]...', 'Execute single task'
    app_options
    local_options
    def exec(task, time, *args)
      require 'sorge/cli/run'
      Run.new(app, task, time, args, options).exec
    end

    desc 'resume SAVEPOINT_FILE_PATH', 'Resume from savepoint'
    app_options
    local_options
    def resume(file_path)
      app.resume(file_path).shutdown
    end

    desc 'start', 'Start sorge server'
    app_options
    option :daemonize, aliases: '-d', desc: 'run in the background'
    option :savepoint, aliases: '-s', banner: 'FILE_PATH',
                       desc: 'resume from savepoint ' \
                             '(from latest savepoint if \'latest\' given)'
    def start
      require 'sorge/cli/daemons'
      Daemons.new(app, options).start
    end

    desc 'stop', 'Stop sorge daemon'
    def stop
      require 'sorge/cli/daemons'
      Daemons.new(app, options).stop
    end

    desc 'submit', 'Submit a job to server'
    def submit(task, time, *args)
      require 'sorge/cli/submit'
      Submit.new(config, task, time, args, options).run
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

require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :environment, aliases: '-e', desc: 'environment'
    class_option :directory, aliases: '-C',
                             desc: 'Change to DIRECTORY before doing anything.'
    class_option :sorgefile, aliases: '-f', desc: 'Sorgefile path'

    def initialize(*args)
      super

      Dir.chdir(options['directory']) if options.include?('directory')
    end

    #
    # Common options
    #
    def self.option_savepoint(default = nil)
      option :savepoint, aliases: '-s', banner: 'FILE_PATH',
                         default: default,
                         desc: 'Resume from savepoint ' \
                               '(from latest savepoint if \'latest\' given)'
    end

    def self.option_dryrun
      option :dryrun, aliases: '-n', type: :boolean, default: false,
                      desc: 'dryrun'
    end

    def self.option_timeout
      option :timeout, aliases: '-t', type: :numeric, default: 60,
                       desc: 'Stop operation timeout in sec.'
    end

    def self.option_daemonize(default = false)
      option :daemonize, aliases: '-d', type: :boolean, default: default,
                         desc: 'run in the background'
    end

    #
    # Task Runner Commands
    #
    desc 'submit', 'Submit a job to server'
    def submit(task, time = Time.now)
      require 'sorge/cli/run'
      Run.new(options).submit(task, time)
    end

    desc 'run TASK [TIME]', 'Run task'
    option_savepoint
    option_dryrun
    def _run(task, time = Time.now)
      require 'sorge/cli/run'
      Run.new(options).run(task, time)
    end
    map run: :_run

    desc 'exec TASK [TIME]', 'Execute single task'
    option_dryrun
    def exec(task, time = Time.now)
      require 'sorge/cli/run'
      Run.new(options).execute(task, time)
    end

    #
    # Server Commands
    #
    desc 'start', 'Start sorge server'
    option_savepoint
    option_daemonize
    def start
      require 'sorge/cli/server'
      Server.new(options).start
    end

    desc 'stop', 'Stop sorge server'
    option_timeout
    def stop
      require 'sorge/cli/server'
      Server.new(options).stop
    end

    desc 'restart', 'Restart sorge server'
    option_daemonize(true)
    option_savepoint('latest')
    option_timeout
    def restart
      require 'sorge/cli/server'
      Server.new(options).stop
      Server.new(options).start
    end

    desc 'kill', 'Kill sorge server'
    def kill
      require 'sorge/cli/server'
      Server.new(options).kill
    end
  end
end

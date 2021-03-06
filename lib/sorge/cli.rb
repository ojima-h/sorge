require 'thor'

require 'sorge'

module Sorge
  class CLI < Thor
    class_option :environment, aliases: '-e', desc: 'environment'
    class_option :directory, aliases: '-C',
                             desc: 'Change to DIRECTORY before doing anything.'
    class_option :sorgefile, aliases: '-f', desc: 'Sorgefile path'
    class_option :libdir, aliases: '-I', type: :array,
                          desc: 'Include LIBDIR in the search path ' \
                                'for required modules.'

    def initialize(*args)
      super

      options['libdir'].each { |d| $LOAD_PATH.unshift(d) } if options['libdir']
      Dir.chdir(options['directory']) if options.include?('directory')
    end

    #
    # Common options
    #
    def self.option_resume(default = nil)
      option :resume, aliases: '-r', banner: 'SAVEPOINT_PATH',
                      default: default,
                      desc: 'Resume from savepoint ' \
                            '(from latest savepoint if \'latest\' given)'
    end

    def self.option_savepoint(default = false)
      option :savepoint, aliases: '-s', type: :boolean,
                         default: default,
                         desc: 'Enable savepoint'
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
    # Jobflow Commands
    #
    desc 'submit', 'Submit a job to server'
    def submit(task, time = nil)
      require 'sorge/cli/jobflow'
      Jobflow.new(options).submit(task, time)
    end

    desc 'run TASK [TIME]', 'Run task'
    option_resume
    option_savepoint(false)
    option_dryrun
    def _run(task, time = nil)
      require 'sorge/cli/jobflow'
      Jobflow.new(options).run(task, time)
    end
    map run: :_run

    desc 'exec TASK [TIME]', 'Execute single task'
    option_dryrun
    def exec(task, time = nil)
      require 'sorge/cli/jobflow'
      Jobflow.new(options).execute(task, time)
    end

    desc 'status', 'Display jobflow status'
    def status
      require 'sorge/cli/jobflow'
      Jobflow.new(options).status
    end

    #
    # Server Commands
    #
    desc 'start', 'Start sorge server'
    option_resume
    option_savepoint(true)
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
    option_resume('latest')
    option_savepoint(true)
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

    desc 'ping', 'Ping server'
    def ping
      require 'sorge/cli/server'
      Server.new(options).ping
    end
  end
end

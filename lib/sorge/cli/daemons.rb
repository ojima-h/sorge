require 'daemons'
require 'sorge/server'

module Sorge
  class Daemons
    def initialize(app, options)
      @app = app
      @options = options

      @daemon_dir = @app.config.get('core.process_dir')
    end

    def start
      daemonize if @options['daemonize']

      resume(@options['savepoint']) if @options['savepoint']

      Sorge::Server.build(@app).run!
    end

    def stop
      app_group = ::Daemons::ApplicationGroup.new(@app.name, daemon_options)
      app_group.setup
      abort 'no process found' if app_group.applications.empty?
      app_group.stop_all
    end

    private

    def daemon_options
      { app_name: @app.name,
        dir_mode: :normal,
        dir: @daemon_dir,
        log_output: true }
    end

    def daemonize
      FileUtils.makedirs(@daemon_dir)
      pwd = Dir.pwd
      ::Daemons.daemonize(daemon_options)
      Dir.chdir pwd
    end

    def resume(file_path)
      file_path = nil if file_path == 'latest'
      @app.resume(file_path)
    end
  end
end

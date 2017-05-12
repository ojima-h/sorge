require 'daemons'

module Sorge
  class Daemons
    def initialize(app, options)
      @app = app
      @options = options

      @process_dir = @app.config.process_dir
    end

    def app_group
      @app_group ||= ::Daemons::ApplicationGroup.new(@app.name, daemon_options)
                                                .tap(&:setup)
    end

    def start
      abort 'sorge server is already running' if app_group.running?

      daemonize
      @app.resume(@options['savepoint']) if @options['savepoint']
      @app.server.start
    end

    def stop
      abort 'no process found' if app_group.applications.empty?
      app_group.stop_all
    end

    private

    def daemon_options
      { ontop: !@options['daemonize'],
        app_name: @app.name,
        dir_mode: :normal,
        dir: @process_dir,
        log_output: true }
    end

    def daemonize
      FileUtils.makedirs(@process_dir)
      pwd = Dir.pwd
      ::Daemons.daemonize(daemon_options)
      Dir.chdir pwd
    end
  end
end

require 'daemons'

module Sorge
  class Daemons
    def initialize(app, daemonize = true)
      @app = app
      @daemonize = daemonize
    end

    def app_group
      @app_group ||=
        ::Daemons::ApplicationGroup.new(@app.config.name, daemons_option)
                                   .tap(&:setup)
    end

    def start
      FileUtils.makedirs(@app.config.process_dir)
      pwd = Dir.pwd

      app_group.new_application(mode: :none).start

      Dir.chdir pwd
    end

    def stop
      app_group.stop_all
    end

    private

    def daemons_option
      { ontop: !@daemonize,
        app_name: @app.config.name,
        dir_mode: :normal,
        dir: @app.config.process_dir,
        log_output: true }
    end
  end
end

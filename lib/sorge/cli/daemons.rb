require 'daemons'

module Sorge
  class Daemons
    def initialize(app, daemonize = true)
      @app = app
      @daemonize = daemonize
      @group = build_application_group

      FileUtils.makedirs(@app.config.process_dir)
    end

    def start
      keepdir { @group.new_application.start }
    end

    def stop
      @group.stop_all
    end

    def signal(sig)
      @group.applications.each do |app|
        begin
          pid = app.pid.pid
          Process.kill(sig, pid)
        rescue Errno::ESRCH
          nil
        end
      end
    end

    private

    def build_application_group
      ::Daemons::ApplicationGroup.new(@app.config.app_name, daemons_option)
                                 .tap(&:setup)
    end

    def daemons_option
      { ontop: !@daemonize,
        mode: :none,
        app_name: @app.config.app_name,
        dir_mode: :normal,
        dir: @app.config.process_dir,
        log_output: true }
    end

    def keepdir
      pwd = Dir.pwd
      yield
    ensure
      Dir.chdir pwd
    end
  end
end

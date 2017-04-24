module Sorge
  class Plugin
    class Command < Plugin
      register :command

      def setup
        app.dsl.define('plugin:command', CommandMixin)
      end

      module CommandMixin
        include DSL::Mixin

        set :command, nil
        set :script, nil

        def run
          cmd = Util.assume_array(command)
          ret = system(*cmd)

          return if ret

          status = $CHILD_STATUS
          status_code = status ? status.exitstatus : 1
          raise "Command faild with status (#{status_code}): " \
                "[#{show_command(cmd)}]"
        end

        def show_command(cmd)
          cmd = cmd.dup

          if cmd.first.is_a?(Hash)
            env = cmd.first
            env = env.map { |name, value| "#{name}=#{value}" }.join ' '
            cmd[0] = env
          end

          cmd.join ' '
        end
      end
    end
  end
end

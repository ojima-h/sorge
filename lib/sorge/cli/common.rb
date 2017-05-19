module Sorge
  class CLI
    module Common
      def build_app(options)
        opts = {}
        %w(sorgefile env dryrun savepoint environment).each do |key|
          opts[key.to_sym] = options[key]
        end
        Application.new(opts)
      end
    end
  end
end

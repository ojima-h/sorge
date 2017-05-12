module Sorge
  class ConfigLoader
    def initialize(options)
      @options = options
      @environment = options[:environment]
      @config_file = options.fetch(:config_file, 'config/sorge.yml')
      @config = nil
    end

    def load
      load_config
      assign_defaults
      merge_options
      @config
    end

    private

    def load_config
      hash = {}
      hash.update(YAML.load_file(@config_file)) if File.file?(@config_file)
      if @environment
        f = File.join(@config_file.gsub(/\.yml$/, ''), @environment + '.yml')
        hash.update(YAML.load_file(f)) if File.file?(f)
      end
      @config = OpenStruct.new(hash)
    end

    def assign_defaults
      @config.app_name ||= 'sorge'
      assign_default_process_dir
      assign_default_savepoint
      assign_default_server
    end

    def assign_default_process_dir
      @config.process_root ||= 'var/sorge'
      @config.process_dir ||=
        if @environment
          File.join(@config.process_root, @environment)
        else
          @config.process_root
        end
    end

    def assign_default_savepoint
      @config.savepoint_path ||= File.join(@config.process_dir, 'savepoints')
      @config.savepoint_interval ||= 10
    end

    def assign_default_server
      @config.server_rpc_port ||= 39_410
      @config.server_rpc_retry ||= 3
    end

    def merge_options
      @config.sorgefile = @options[:sorgefile]
    end
  end
end

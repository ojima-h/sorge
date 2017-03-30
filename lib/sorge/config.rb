module Sorge
  class Config
    extend Forwardable

    DEFAULT_CONFIG_FILE = 'config/sorge.yml'.freeze

    OPTIONS_PATH = {
      sorgefile: 'core.sorgefile'
    }.freeze

    DEFAULTS = {
      'server.host' => 'localhost',
      'server.port' => 9900
    }.freeze

    def initialize(options = {})
      @hash = load_yaml(options[:config_file])
      merge_options(options)
      assign_defaults
    end
    def_delegators :@hash, :[], :[]=, :fetch

    def get(path)
      keys = path.to_s.split('.').map(&:to_sym)
      dig(*keys)
    end

    def dig(*keys)
      keys.inject(@hash) do |a, e|
        return nil unless a.is_a?(Hash)
        a[e]
      end
    end

    def set(path, value)
      *parents, key = path.to_s.split('.').map(&:to_sym)
      h = parents.inject(@hash) do |a, e|
        a[e] = {} unless a[e].is_a?(Hash)
        a[e]
      end
      h[key] = value
    end

    def set_default(path, value)
      *parents, key = path.to_s.split('.').map(&:to_sym)
      h = parents.inject(@hash) do |a, e|
        a[e] ||= {}
        return nil unless a[e].is_a?(Hash)
        a[e]
      end
      h[key] ||= value
    end

    private

    def load_yaml(file_path)
      return {} if file_path.nil? && !File.file?(DEFAULT_CONFIG_FILE)

      Util.symbolize_keys(YAML.load_file(file_path || DEFAULT_CONFIG_FILE))
    end

    def merge_options(options)
      options.each do |key, val|
        next unless OPTIONS_PATH.include?(key)
        set(OPTIONS_PATH[key], val)
      end
    end

    def assign_defaults
      DEFAULTS.each do |path, value|
        set_default(path, value)
      end
    end
  end
end

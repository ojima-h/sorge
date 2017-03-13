require 'yaml'

module Sorge
  class Application
    def initialize(config_file: nil)
      @config = load_config(config_file)
    end
    attr_reader :config

    def model
      @model ||= Model.new(self)
    end

    private

    def load_config(file_path = nil)
      return {} if file_path.nil?
      @config = Util.symbolize_keys(YAML.load_file(file_path))
    end
  end
end

require 'yaml'

module Sorge
  class Application
    def initialize(config_file: nil)
      @config = load_config(config_file)
      @model = Model.new(self)
      @dsl = DSL.new(self)
    end
    attr_reader :config, :model, :dsl

    private

    def load_config(file_path = nil)
      return {} if file_path.nil?
      @config = Util.symbolize_keys(YAML.load_file(file_path))
    end
  end
end

module Sorge
  class Application
    def initialize(config_file: nil)
      @config = load_config(config_file)
      @dsl = DSL.new(self)
      @engine = Engine.new(self)
      @model = Model.new(self)
    end
    attr_reader :config, :dsl, :engine, :model

    private

    def load_config(file_path = nil)
      return {} if file_path.nil?
      @config = Util.symbolize_keys(YAML.load_file(file_path))
    end
  end
end

require 'sorge/dsl'
require 'sorge/engine'
require 'sorge/model'

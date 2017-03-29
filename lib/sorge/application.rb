module Sorge
  class Application
    def initialize(options = {})
      @options = options
      @dsl = DSL.new(self)
      @engine = Engine.new(self)
      @model = Model.new(self)

      load_config
      load_sorgefile
    end
    attr_reader :options, :dsl, :engine, :model, :config

    def invoke(task_name, params)
      task = dsl.task_manager[task_name]
      engine.driver.invoke(task, params)
    end

    private

    def load_config
      @config = if options[:config_file]
                  Util.symbolize_keys(YAML.load_file(options[:config_file]))
                else
                  {}
                end
    end

    def load_sorgefile
      @sorgefile = find_sorgefile
      load(@sorgefile) if @sorgefile
    end

    def find_sorgefile
      return options[:sorgefile] if options[:sorgefile]

      %w(Sorgefile Sorgefile.rb).each do |filename|
        return filename if File.file?(filename)
      end

      nil
    end
  end
end

require 'sorge/dsl'
require 'sorge/engine'
require 'sorge/model'

module Sorge
  class Application
    def initialize(options = {})
      @config = options[:config] || Config.new(options)

      @dsl = DSL.new(self)
      @engine = Engine.new(self)
      @model = Model.new(self)

      load_sorgefile
    end
    attr_reader :config, :dsl, :engine, :model, :config

    def invoke(task_name, params)
      task = dsl.task_manager[task_name]
      engine.driver.invoke(task, params)
    end

    private

    def load_sorgefile
      @sorgefile = find_sorgefile
      load(@sorgefile) if @sorgefile
    end

    def find_sorgefile
      config.get('core.sorgefile').tap { |f| return f if f }

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

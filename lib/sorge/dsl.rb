module Sorge
  class DSL
    class << self
      attr_accessor :current
    end

    def initialize(application)
      @application = application
      @global_mixin = Mixin.create_global_mixin(self)
      @task_manager = TaskManager.new(self)

      self.class.current = self
    end
    attr_reader :application, :global_mixin, :task_manager
  end
end

require 'sorge/dsl/core'
require 'sorge/dsl/linked_list'
require 'sorge/dsl/mixin'
require 'sorge/dsl/syntax'
require 'sorge/dsl/scope'
require 'sorge/dsl/task_manager'
require 'sorge/dsl/task'

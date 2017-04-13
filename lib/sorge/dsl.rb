module Sorge
  class DSL
    extend MonitorMixin

    class << self
      attr_accessor :current
    end

    def initialize(application)
      @application = application
      @global = Base.create(self, :global)
      @task_manager = TaskManager.new(self)
      @task_graph = TaskGraph.new(self)
    end
    attr_reader :application, :global, :task_manager, :task_graph

    def with_current
      DSL.synchronize do
        begin
          orig = DSL.current
          DSL.current = self
          yield
        ensure
          DSL.current = orig
        end
      end
    end
  end
end

require 'sorge/dsl/concern'

require 'sorge/dsl/core'
require 'sorge/dsl/core_action'
require 'sorge/dsl/core_include'
require 'sorge/dsl/core_settings'
require 'sorge/dsl/core_upstreams'
require 'sorge/dsl/core_window'

require 'sorge/dsl/base'
require 'sorge/dsl/mixin'
require 'sorge/dsl/task'

require 'sorge/dsl/linked_list'
require 'sorge/dsl/syntax'
require 'sorge/dsl/scope'
require 'sorge/dsl/task_graph'
require 'sorge/dsl/task_manager'
require 'sorge/dsl/window'

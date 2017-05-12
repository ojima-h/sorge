module Sorge
  class DSL
    extend MonitorMixin
    extend Forwardable
    include Singleton

    def initialize
      @global = Base.create(self, :global)
      @task_manager = TaskManager.new(self)
      @task_graph = TaskGraph.new(self)
    end
    attr_reader :global, :task_manager, :task_graph
    def_delegators :@task_manager, :define, :[]
  end
end

require 'sorge/dsl/concern'

require 'sorge/dsl/core'
require 'sorge/dsl/core_emit'
require 'sorge/dsl/core_hook'
require 'sorge/dsl/core_settings'
require 'sorge/dsl/core_time'
require 'sorge/dsl/core_upstreams'
require 'sorge/dsl/core_use'

require 'sorge/dsl/base'
require 'sorge/dsl/mixin'
require 'sorge/dsl/task'

require 'sorge/dsl/linked_list'
require 'sorge/dsl/syntax'
require 'sorge/dsl/scope'
require 'sorge/dsl/task_graph'
require 'sorge/dsl/task_manager'
require 'sorge/dsl/time_trunc'
require 'sorge/dsl/trigger'

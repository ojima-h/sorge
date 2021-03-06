module Sorge
  class DSL
    extend MonitorMixin
    extend Forwardable

    def initialize(app)
      @app = app
      @tasks = TaskCollection.new(self)
    end
    attr_reader :app, :tasks

    def self.task_definition
      @task_definition ||= TaskDefinition.new
    end
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
require 'sorge/dsl/core_worker'

require 'sorge/dsl/base'
require 'sorge/dsl/mixin'
require 'sorge/dsl/task'

require 'sorge/dsl/linked_list'
require 'sorge/dsl/syntax'
require 'sorge/dsl/scope'
require 'sorge/dsl/task_collection'
require 'sorge/dsl/task_definition'
require 'sorge/dsl/time_trunc'
require 'sorge/dsl/trigger'

require 'sequel/plugins/serialization'
require 'yaml'

module Sorge
  class Model
    EventQueue = define_model(:event_queue) do
      class << self
        def connected
          plugin :timestamps
          plugin :serialization, :yaml, :data
        end

        def queue
          @queue ||= Queue.new(self)
        end

        def get
          queue.get
        end

        def post(name, data = {})
          queue.post(name: name, data: data)
        end

        def delete(id)
          queue.delete(id)
        end
      end
    end
  end
end

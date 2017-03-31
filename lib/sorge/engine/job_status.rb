module Sorge
  class Engine
    # JobsStatus represents each status of a job.
    class JobStatus
      STATES = %w(unscheduled pending running successed failed cancelled).freeze

      STATES.each do |state|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def self.#{state}(*args)
          #{state.capitalize}.instance(*args)
        end
        RUBY
      end

      # Base class for job statuses
      class Base
        def name
          self.class.name.split('::').last.downcase
        end

        STATES.each do |n|
          define_method(n + '?') { name == n }
        end

        def complete?
          successed? || failed? || cancelled?
        end

        def step(_message, *_args)
          self
        end

        def self.instance
          @instance ||= new
        end
      end

      # Initial status
      class Unscheduled < Base
        def initialize(num_waiting)
          @num_waiting = num_waiting
        end
        attr_reader :num_waiting

        def step(message, *args)
          case message
          when :predecessor_finished
            predecessor_finished(*args)
          when :kill
            Cancelled.instance
          else
            self
          end
        end

        def predecessor_finished(status)
          if status.successed?
            Unscheduled.instance(num_waiting - 1)
          else
            Cancelled.instance
          end
        end

        def self.instance(num_waiting)
          if num_waiting > 0
            new(num_waiting)
          else
            Pending.instance
          end
        end
      end

      # Pending status: waiting for workers to start processing.
      class Pending < Base
        def step(message)
          case message
          when :start
            Running.instance
          when :failed, :kill
            Failed.instance
          else
            self
          end
        end
      end

      # Running status: workers are now executing the job.
      class Running < Base
        def step(message)
          case message
          when :successed
            Successed.instance
          when :failed, :kill
            Failed.instance
          else
            self
          end
        end
      end

      # Successed status
      class Successed < Base; end

      # Failed status
      class Failed < Base; end

      # Cancelled status: the job is cancelled because some predecessors were
      # failed.
      class Cancelled < Base; end
    end
  end
end

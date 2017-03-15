module Sorge
  class Engine
    # JobsStatus represents each status of a job.
    class JobStatus
      # Base class for job statuses
      class Base
        def self.fields(*keys)
          @fields ||= []
          return @fields if keys.empty?

          @fields = keys
          keys.each do |key|
            define_method(key) { @opts[key] }
          end
        end

        def initialize(opts = {})
          keys = self.class.fields
          vals = opts.values_at(*keys)
          @opts = keys.zip(vals).to_h
        end

        def to(next_status, opts = {})
          next_status.new(@opts.merge(opts))
        end

        def name
          self.class.name.split('::').last.downcase
        end

        %w(unscheduled pending
           running successed failed cancelled).each do |n|
          define_method(n + '?') { name == n }
        end

        def complete?
          successed? || failed? || cancelled?
        end

        def predecessor_finished(_status)
          self
        end

        def start(_params)
          self
        end

        def successed
          self
        end

        def failed(_error)
          self
        end

        def cancelled
          self
        end

        def killed
          to Cancelled
        end
      end

      # Initial status
      class Unscheduled < Base
        fields :num_waiting

        def predecessor_finished(status)
          case status
          when Successed
            predecessor_successed
          else # Failed, Cancelled
            to Cancelled
          end
        end

        private

        def predecessor_successed
          if num_waiting > 1
            to Unscheduled, num_waiting: num_waiting - 1
          else
            to Pending
          end
        end
      end

      # Pending status: waiting for workers to start processing.
      class Pending < Base
        # `params` is assigned to jobs invoked via JobManager#invoke.
        fields :params

        def start(params)
          to Running, params: params, start_time: Time.now
        end
      end

      # Running status: workers are now executing the job.
      class Running < Base
        fields :params, :start_time

        def successed
          to Successed, end_time: Time.now
        end

        def failed(error)
          to Failed, error: error, end_time: Time.now
        end
      end

      # Common features of complete statuses
      module Complete
        def killed
          self
        end
      end

      # Successed status
      class Successed < Base
        include Complete
        fields :params, :start_time, :end_time
      end

      # Failed status
      class Failed < Base
        include Complete
        fields :params, :error, :start_time, :end_time
      end

      # Cancelled status: the job is cancelled because some predecessors were
      # failed.
      class Cancelled < Base
        include Complete
      end
    end
  end
end

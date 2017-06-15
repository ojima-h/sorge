module Sorge
  class DSL
    module CoreWorker
      include Core

      class_methods do
        def init(app, name)
          super
          @_worker = nil
        end
        attr_reader :_worker

        def worker(name = nil)
          if name
            app.worker.validate_name!(worker)
            @_worker = name
          else
            o = super_mixins.find(&:_worker)
            o ? o._worker : :default
          end
        end
      end
    end
  end
end

global do
  def run
    if defined?(SorgeTest)
      SorgeTest.spy(name: task.name, time: time)
      SorgeTest.hook[task.name].call(self) if SorgeTest.hook.include?(task.name)
    else
      puts self
    end
  end

  class_methods do
    def h1
      :h1
    end
  end
end

task :t1

task :t2 do
  upstream :t1
end

namespace :test_namespace do
  namespace :ns do
    task :t1

    task :t2 do
      upstream :t1
    end

    mixin :m1 do
      upstream :t1
    end
  end

  task :t3 do
    use 'ns:m1'

    upstream 'ns:t2'
  end

  task :t4 do
    upstream 'test_namespace:ns:t1'
    upstream 'test_namespace:t3'
  end
end

namespace :test_failure do
  task :t1

  task :t2 do
    upstream :t1
    def run
      super
      raise 'test'
    end
  end
  task(:t3) { upstream :t1 }

  task(:t4) { upstream :t2 }
  task(:t5) { upstream :t3 }

  task :t6 do
    upstream :t4
    upstream :t5
  end

  task :t7 do
    before { raise 'test' }
  end

  task :fatal do
    def run
      super
      raise Exception, 'test fatal'
    end
  end
end

namespace :test_window do
  task :t0
  task :t1 do
    upstream :t0
  end
  task :t2

  task :t3 do
    window 3
    upstream :t1
    upstream :t2
  end

  task :t4 do
    window :daily
    upstream :t1
  end

  task :t5 do
    window :daily, delay: 0
    upstream :t2
    upstream :t4
  end
end

namespace :test_hook do
  mixin :m1 do
    successed { SorgeTest.spy(name: :successed_in_mixin) }
  end

  task :t1 do
    use :m1

    before { SorgeTest.spy(name: :before) }

    def run
      SorgeTest.spy(name: :run)
    end

    successed { SorgeTest.spy(name: :successed) }
    failed { |error| SorgeTest.spy(name: :failed, error: error) }
    after { SorgeTest.spy(name: :after) }
  end

  task :t2 do
    before { SorgeTest.spy(name: :before) }

    def run
      raise 'test'
    end

    successed { SorgeTest.spy(name: :successed) }
    failed { |error| SorgeTest.spy(name: :failed, error: error) }
    after { SorgeTest.spy(name: :after) }
  end
end

namespace :test_emit do
  task :t1 do
    def run
      super
      emit 100
      emit 200
      emit 300
    end
  end

  task :t2 do
    upstream :t1
  end
end

namespace :test_plugin do
  task :t1 do
    use 'plugin:command'

    set :command, ['ls', '.']
  end
end

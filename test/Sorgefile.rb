global do
  def run
    if defined?(SorgeTest)
      SorgeTest.spy(task.name)
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
    include 'ns:m1'

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
    setup { raise 'test' }
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
    window :daily, delay: 60
    upstream :t1
  end

  task :t5 do
    window :daily
    upstream :t2
    upstream :t4
  end
end

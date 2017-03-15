global_mixin do
  def spy(*args)
    if defined?(:SorgeTest)
      SorgeTest.spy << [task.name, *args]
    else
      puts [name, *args].join(' ')
    end
  end

  action { spy }

  helpers do
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
    action { raise 'test' }
  end
  task(:t3) { upstream :t1 }

  task(:t4) { upstream :t2 }
  task(:t5) { upstream :t3 }

  task :t6 do
    upstream :t4
    upstream :t5
  end
end

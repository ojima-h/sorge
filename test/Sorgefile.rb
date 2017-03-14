global_mixin do
  def spy(*args)
    if defined?(:SorgeTest)
      SorgeTest.spy << [name, *args]
    else
      puts [name, *args].join(' ')
    end
  end

  helpers do
    def h1
      :h1
    end
  end
end

task :t1 do
  action { spy }
end

task :t2 do
  upstream :t1

  action { spy }
end

namespace :ns1 do
  namespace :ns2 do
    task :t1 do
      action { spy }
    end

    task :t2 do
      upstream :t1
      action { spy }
    end

    mixin :m1 do
      upstream :t1
    end
  end

  task :t3 do
    include 'ns2:m1'

    upstream 'ns2:t2'
    action { spy }
  end

  task :t4 do
    upstream 'ns1:ns2:t1'
    upstream 'ns1:t3'
  end
end

require 'test_helper'
require 'sorge/server'

module Sorge
  class ServerTest < SorgeTest
    def test_submit
      f = Concurrent::Future.execute { app.server.start }

      spy = []
      app.stub(:submit, ->(*args) { spy << args }) do
        Server.client(app.config).call(:submit, name: 't1', time: now)
      end
      assert_equal [['t1', Util::Time(now.to_s)]], spy
    ensure
      app.server.stop
      f.wait!
    end

    def test_error
      f = Concurrent::Future.execute { app.server.start }

      app.server.stub(:handle_submit, ->(_) { raise 'test' }) do
        assert_raises Server::Error do
          Server.client(app.config).call(:submit, name: 't1', time: now)
        end
      end
    ensure
      app.server.stop
      f.wait!
    end
  end
end

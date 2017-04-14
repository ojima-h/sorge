require 'test_helper'
require 'sorge/server'

module Sorge
  class ServerTest < SorgeTest
    def test_submit
      f = Concurrent::Future.execute { app.server.start }

      spy = []
      app.stub(:submit, ->(*args) { spy << args }) do
        Server.client(@app.config).call(:submit, name: 't1', time: 100)
        app.server.stop
        f.wait!
      end

      assert_equal [['t1', 100]], spy
    end
  end
end

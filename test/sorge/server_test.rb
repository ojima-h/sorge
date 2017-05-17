require 'test_helper'
require 'sorge/server'

module Sorge
  class ServerTest < SorgeTest
    def test_submit
      f = Concurrent::Future.execute { app.server.start }
      sleep 0.01 until app.server.status == :Running

      spy = []
      app.stub(:submit, ->(*args) { spy << args }) do
        app.server.client.call('jobflow.submit', 't1', now.to_i)
      end
      assert_equal [['t1', Time.at(now.to_i)]], spy
    ensure
      app.server.stop
      f.wait!
    end

    def test_error
      f = Concurrent::Future.execute { app.server.start }
      sleep 0.01 until app.server.status == :Running

      app.stub(:submit, ->(*) { raise 'test' }) do
        assert_raises XMLRPC::FaultException do
          app.server.client.call('jobflow.submit', 't1', now.to_i)
        end
      end
    ensure
      app.server.stop
      f.wait!
    end
  end
end

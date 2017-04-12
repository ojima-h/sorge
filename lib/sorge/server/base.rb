module Sorge
  class Server
    class Base < Sinatra::Base
      set :sorge, nil

      helpers(Helper)

      get '/version' do
        Sorge::VERSION
      end

      post '/jobs' do
        json_body

        task_name = params[:json][:task]
        time = Util.parse_time(params[:json][:time] || Time.now.to_i)

        sorge.submit(task_name, time)

        200
      end
    end
  end
end

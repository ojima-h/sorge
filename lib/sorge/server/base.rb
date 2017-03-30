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
        task_params = params[:json][:params] || {}

        jobflow = sorge.invoke(task_name, task_params)
        jobflow.wait unless params[:json][:async]

        200
      end
    end
  end
end

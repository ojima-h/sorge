module Sorge
  class Server
    # SorgeServer helper
    module Helper
      def sorge
        settings.sorge
      end

      #
      # JSON request / response
      #
      def json(object)
        content_type :json
        JSON.dump(object)
      end

      def json_body
        request.body.rewind # in case someone already read it
        body = JSON.parse(request.body.read, symbolize_names: true)
        params[:json] = body
      end
    end
  end
end

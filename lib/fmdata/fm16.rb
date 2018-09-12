require "fmdata/fm16/token_session"
require "uri"

module FmData
  module FM16
    BASE_PATH = "/fmi/rest/api/".freeze
    SERVICES = %w[ auth record find ].freeze

    class << self
      def build_connection(options = FmData.config)
        base_connection(options) do |conn|
          conn.use      TokenSession, options
          conn.request  :json
          conn.response :logger, nil, bodies: true
          conn.response :json
          conn.adapter  Faraday.default_adapter
        end
      end

      def base_connection(options = FmData.config, &block)
        Faraday.new("https://" + options.fetch(:host) + BASE_PATH, &block)
      end

      # Format for Data API URLs: /fmi/rest/api/:service/:solution/:layout/:recordId where 
      #
      #   :service is a pre-defined service keyword, such as auth, record, or find
      #   :solution is the name of a hosted FileMaker solution
      #   :layout is the name of the layout to be used as the context for the request
      #   :recordId is the unique ID number for a record
      #
      def build_path(service, solution, *layout_and_record_id)
        service = service.to_s

        raise "service must be one of `auth', `record' or `find'" unless SERVICES.include?(service)

        # solution is URI.escape'd because it could contain spaces, which we need
        # to replace with %20 (according to RFC 3986). Note that some URI
        # escaping APIs such as CGI::Util.escape or Faraday::Utils.escape replace
        # spaces with +, which we don't want here.
        solution = URI.escape(solution)

        [service, solution, *layout_and_record_id.first(2).map { |s| URI.escape(s) }].join("/")
      end
    end
  end
end

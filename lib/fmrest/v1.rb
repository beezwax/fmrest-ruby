require "fmrest/v1/token_session"
require "fmrest/v1/raise_errors"
require "fmrest/v1/utils"
require "uri"

module FmRest
  module V1
    BASE_PATH = "/fmi/data/v1/databases".freeze

    class << self
      include Utils

      def build_connection(options = FmRest.config, &block)
        base_connection(options) do |conn|
          conn.use RaiseErrors
          conn.use TokenSession, options

          # The EncodeJson and Multipart middlewares only encode the request
          # when the content type matches, so we can have them both here and
          # still play nice with each other, we just need to set the content
          # type to multipart/form-data when we want to submit a container
          # field
          conn.request :multipart
          conn.request :json

          if options[:log]
            conn.response :logger, nil, bodies: true, headers: true
          end

          # Allow overriding the default response middleware
          if block_given?
            yield conn
          else
            conn.response :json
          end

          conn.adapter Faraday.default_adapter
        end
      end

      def base_connection(options = FmRest.config, &block)
        host = options.fetch(:host)

        # Default to HTTPS
        scheme = "https"

        if host.match(/\Ahttps?:\/\//)
          uri = URI(host)
          host = uri.hostname
          host += ":#{uri.port}" if uri.port != uri.default_port
          scheme = uri.scheme
        end

        Faraday.new("#{scheme}://#{host}#{BASE_PATH}/#{URI.escape(options.fetch(:database))}/".freeze, &block)
      end

      def session_path(token = nil)
        url = "sessions"
        url += "/#{token}" if token
        url
      end

      def record_path(layout, id = nil)
        url = "layouts/#{URI.escape(layout.to_s)}/records"
        url += "/#{id}" if id
        url
      end

      def container_field_path(layout, id, field_name, field_repetition = 1)
        url = record_path(layout, id)
        url += "/containers/#{URI.escape(field_name.to_s)}"
        url += "/#{field_repetition}" if field_repetition
        url
      end

      def find_path(layout)
        "layouts/#{URI.escape(layout.to_s)}/_find"
      end

      #def globals_path
      #end

      # Given a container field URL it tries to fetch it and returns an IO
      # object with its body content (see Ruby's OpenURI for how the IO object
      # is extended with useful HTTP response information).
      #
      # In case of failure a FmRest::ContainerFieldError will be raised.
      #
      # This method uses Net::HTTP and OpenURI instead of Faraday.
      #
      def fetch_container_field(container_field_url)
        require "open-uri"

        begin
          url = URI(container_field_url)
        rescue ::URI::InvalidURIError
          raise FmRest::ContainerFieldError, "Invalid container field URL `#{container_field_url}'"
        end

        # Make sure we don't try to open anything on the file:/ URI scheme
        unless url.scheme.match(/\Ahttps?\Z/)
          raise FmRest::ContainerFieldError, "Container URL is not HTTP (#{container_field_url})"
        end

        require "net/http"

        # Requesting the container URL with no cookie set will respond with a
        # redirect and a session cookie
        cookie_response = ::Net::HTTP.get_response(url)

        unless cookie = cookie_response["Set-Cookie"]
          raise FmRest::ContainerFieldError, "Container field's initial request didn't return a session cookie, the URL may be stale (try downloading it again immediately after retrieving the record)"
        end

        # Now request the URL again with the proper session cookie using
        # OpenURI, which wraps the response in an IO object which also responds
        # to #content_type
        url.open("Cookie" => cookie)
      end
    end
  end
end

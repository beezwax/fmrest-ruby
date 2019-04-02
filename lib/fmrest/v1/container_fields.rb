module FmRest
  module V1
    module ContainerFields
      DEFAULT_UPLOAD_CONTENT_TYPE = "application/octet-stream".freeze

      # Given a container field URL it tries to fetch it and returns an IO
      # object with its body content (see Ruby's OpenURI for how the IO object
      # is extended with useful HTTP response information).
      #
      # This method uses Net::HTTP and OpenURI instead of Faraday.
      #
      # @raise [FmRest::ContainerFieldError] if any step fails
      # @param container_field_url [String] the URL to the container to
      #   download
      # @return [IO] the contents of the container
      def fetch_container_data(container_field_url)
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

      # Handles the core logic of uploading a file into a container field
      #
      # @param connection [Faraday] the Faraday connection to use
      # @param container_path [String] the path to the container
      # @param filename_or_io [String, IO] a path to the file to upload or an
      #   IO object
      # @param options [Hash]
      # @option options [String] :content_type (DEFAULT_UPLOAD_CONTENT_TYPE)
      #   The content type for the uploaded file
      # @option options [String] :filename The filename to use for the uploaded
      #   file, defaults to `filename_or_io.original_filename` if available
      def upload_container_data(connection, container_path, filename_or_io, options = {})
        content_type = options[:content_type] || DEFAULT_UPLOAD_CONTENT_TYPE

        connection.post do |request|
          request.url container_path
          request.headers['Content-Type'] = ::Faraday::Request::Multipart.mime_type

          filename = options[:filename] || filename_or_io.try(:original_filename)

          request.body = { upload: Faraday::UploadIO.new(filename_or_io, content_type, filename) }
        end
      end
    end
  end
end

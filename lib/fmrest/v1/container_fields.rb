# frozen_string_literal: true

module FmRest
  module V1
    module ContainerFields
      DEFAULT_UPLOAD_CONTENT_TYPE = "application/octet-stream".freeze

      # Given a container field URL it tries to fetch it and returns an IO
      # object with its body content (see Ruby's OpenURI for how the IO object
      # is extended with useful HTTP response information).
      #
      # This method uses OpenURI instead of Faraday for fetching the actual
      # container file.
      #
      # @raise [FmRest::ContainerFieldError] if any step fails
      # @param container_field_url [String] The URL to the container to
      #   download
      # @param base_connection [Faraday::Connection] An optional Faraday
      #   connection to use as base settings for the container requests, useful
      #   if you need to set SSL or proxy settings. If given, this connection
      #   will not be used directly, but rather a new one with copied SSL and
      #   proxy options. If omitted, `FmRest.default_connection_settings`'s
      #   `:ssl` and `:proxy` options will be used instead (if available)
      # @return [IO] The contents of the container
      def fetch_container_data(container_field_url, base_connection = nil)
        require "open-uri"

        if container_field_url == ""
          raise FmRest::ContainerFieldError, "Container field URL is empty string"
        end

        begin
          url = URI(container_field_url)
        rescue ::URI::InvalidURIError, ArgumentError
          raise FmRest::ContainerFieldError, "Invalid container field URL `#{container_field_url}'"
        end

        # Make sure we don't try to open anything on the file:/ URI scheme
        unless url.scheme.match(/\Ahttps?\Z/)
          raise FmRest::ContainerFieldError, "Container field URL is not HTTP (#{container_field_url})"
        end

        ssl_options = base_connection && base_connection.ssl && base_connection.ssl.to_hash
        proxy_options = base_connection && base_connection.proxy && base_connection.proxy.to_hash

        conn =
          Faraday.new(nil,
            ssl:   ssl_options || FmRest.default_connection_settings[:ssl],
            proxy: proxy_options || FmRest.default_connection_settings[:proxy]
          )

        openuri_options =
          faraday_connection_to_openuri_options(conn).merge(redirect: false)

        begin
          url.open(openuri_options)
        rescue OpenURI::HTTPRedirect => e
          unless cookie = e.io.metas.dig("set-cookie", 0)
            raise FmRest::ContainerFieldError, "Container field's initial request didn't return a session cookie, the URL may be stale (try downloading it again immediately after retrieving the record)"
          end

          url = if e.io.meta["location"].match(/\Ahttps?:/)
            URI(e.io.meta["location"])
          else
            URI.join("#{url.scheme}://#{url.host}:#{url.port}", e.io.meta["location"])
          end

          # Now request the URL again with the proper session cookie using
          # OpenURI, which wraps the response in an IO object which also responds
          # to #content_type
          url.open(openuri_options.merge("Cookie" => cookie))
        end
      end

      # Handles the core logic of uploading a file into a container field
      #
      # @param connection [Faraday::Connection] the Faraday connection to use
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
          request.headers['Content-Type'] = "multipart/form-data"

          filename = options[:filename] || filename_or_io.try(:original_filename)

          request.body = { upload: Faraday::Multipart::FilePart.new(filename_or_io, content_type, filename) }
        end
      end

      private

      # Copies a Faraday::Connection's relevant options to
      # OpenURI::OpenRead#open format
      #
      def faraday_connection_to_openuri_options(conn)
        openuri_opts = {}

        if !conn.ssl.empty?
          openuri_opts[:ssl_verify_mode] =
            conn.ssl.fetch(:verify, true) ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

          openuri_opts[:ssl_ca_cert] = conn.ssl.cert_store if conn.ssl.cert_store
        end

        if conn.proxy && !conn.proxy.empty?
          if conn.proxy.user && conn.proxy.password
            openuri_opts[:proxy_http_basic_authentication] =
              [conn.proxy.uri.tap { |u| u.userinfo = ""}, conn.proxy.user, conn.proxy.password]
          else
            openuri_opts[:proxy] = conn.proxy.uri
          end
        end

        openuri_opts
      end
    end
  end
end

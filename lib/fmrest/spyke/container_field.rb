module FmRest
  module Spyke
    class ContainerField
      DEFAULT_CONTENT_TYPE = "application/octet-stream".freeze

      attr_reader :name

      def initialize(base, name)
        @base = base
        @name = name
      end

      def url
        @base.attributes[name]
      end

      def download
        FmRest::V1.fetch_container_field(url)
      end

      def upload(filename_or_io, options = {})
        raise ArgumentError, "Record needs to be saved before uploading to a container field" unless @base.persisted?

        repetition = options[:repetition] || 1
        content_type = options[:content_type] || DEFAULT_CONTENT_TYPE

        response =
          @base.class.connection.post do |request|
            request.url upload_path(repetition)
            request.headers['Content-Type'] = ::Faraday::Request::Multipart.mime_type
            # TODO: Do we care about the content type? Currently sending
            # application/octet-stream every time
            request.body = { upload: Faraday::UploadIO.new(filename_or_io, content_type) }
          end

        # Update mod id on record
        @base.mod_id = response.body[:data][:mod_id]

        true
      end

      private

      def upload_path(repetition)
        FmRest::V1.container_field_path(@base.class.layout, @base.id, name, repetition)
      end
    end
  end
end

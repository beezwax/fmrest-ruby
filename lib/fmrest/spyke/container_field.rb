module FmRest
  module Spyke
    class ContainerField

      attr_reader :name

      def initialize(base, name)
        @base = base
        @name = name
      end

      def url
        @base.attributes[name]
      end

      def download
        FmRest::V1.fetch_container_data(url)
      end

      def upload(filename_or_io, options = {})
        raise ArgumentError, "Record needs to be saved before uploading to a container field" unless @base.persisted?

        response =
          FmRest::V1.upload_container_data(
            @base.class.connection,
            upload_path(options[:repetition] || 1),
            filename_or_io,
            options
          )

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

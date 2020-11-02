# frozen_string_literal: true

module FmRest
  module Spyke
    class ContainerField

      # @return [String] the name of the container field
      attr_reader :name

      # @param base [FmRest::Spyke::Base] the record this container belongs to
      # @param name [Symbol] the name of the container field
      def initialize(base, name)
        @base = base
        @name = name
      end

      # @return [String] the URL for the container
      def url
        @base.attributes[name]
      end

      # @return (see FmRest::V1::ContainerFields#fetch_container_data)
      def download
        FmRest::V1.fetch_container_data(url, @base.class.connection)
      end

      # @param filename_or_io [String, IO] a path to the file to upload or an
      #   IO object
      # @param options [Hash]
      # @option options [Integer] :repetition (1) The repetition to pass to the
      #   upload URL
      # @option (see FmRest::V1::ContainerFields#upload_container_data)
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
        @base.__mod_id = response.body[:data][:__mod_id]

        true
      end

      private

      # @param repetition [Integer]
      # @return [String] the path for uploading a file to the container
      def upload_path(repetition)
        FmRest::V1.container_field_path(@base.class.layout, @base.__record_id, name, repetition)
      end
    end
  end
end

# frozen_string_literal: true

require "fmrest/errors"

module FmRest
  module V1
    # FM Data API response middleware for raising exceptions on API response
    # errors
    #
    # https://fmhelp.filemaker.com/help/17/fmp/en/index.html#page/FMP_Help/error-codes.html
    #
    class RaiseErrors < Faraday::Response::Middleware
      # https://fmhelp.filemaker.com/help/17/fmp/en/index.html#page/FMP_Help/error-codes.html
      ERROR_RANGES = {
        -1         => APIError::UnknownError,
        100        => APIError::ResourceMissingError,
        101        => APIError::RecordMissingError,
        102..199   => APIError::ResourceMissingError,
        200..299   => APIError::AccountError,
        300..399   => APIError::LockError,
        400        => APIError::ParameterError,
        401        => APIError::NoMatchingRecordsError,
        402..499   => APIError::ParameterError,
        500..599   => APIError::ValidationError,
        800..899   => APIError::SystemError,
        1200..1299 => APIError::ScriptError,
        1400..1499 => APIError::ODBCError
      }

      def on_complete(env)
        # Sniff for either straight JSON parsing or Spyke's format
        if env.body[:metadata] && env.body[:metadata][:messages]
          check_errors(env.body[:metadata][:messages])
        elsif env.body["messages"]
          check_errors(env.body["messages"])
        end
      end

      private

      def check_errors(messages)
        messages.each do |message|
          error_code = (message["code"] || message[:code]).to_i

          # Code 0 means "No Error"
          next if error_code.zero?

          error_message = message["message"] || message[:message]

          *, exception_class = ERROR_RANGES.find { |k, v| k === error_code }

          raise (exception_class || APIError).new(error_code, error_message)
        end
      end
    end
  end
end

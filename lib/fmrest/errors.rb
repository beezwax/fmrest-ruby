# frozen_string_literal: true

module FmRest
  class Error < StandardError; end

  class APIError < Error
    attr_reader :code

    def initialize(code, message = nil)
      @code = code
      super("FileMaker Data API responded with error #{code}: #{message}")
    end
  end

  class APIError::UnknownError < APIError; end         # error code -1
  class APIError::ResourceMissingError < APIError; end # error codes 100..199
  class APIError::RecordMissingError < APIError::ResourceMissingError; end
  class APIError::AccountError < APIError; end         # error codes 200..299
  class APIError::LockError < APIError; end            # error codes 300..399
  class APIError::ParameterError < APIError; end       # error codes 400..499
  class APIError::NoMatchingRecordsError < APIError::ParameterError; end
  class APIError::ValidationError < APIError; end      # error codes 500..599
  class APIError::SystemError < APIError; end          # error codes 800..899
  class APIError::InvalidToken < APIError; end         # error code 952
  class APIError::MaximumDataAPICallsExceeded < APIError; end # error code 953
  class APIError::ScriptError < APIError; end          # error codes 1200..1299
  class APIError::ODBCError < APIError; end            # error codes 1400..1499

  class ContainerFieldError < Error; end
end

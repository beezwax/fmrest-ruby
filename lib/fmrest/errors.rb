module FmRest
  class Error < StandardError; end

  class APIError < Error
    attr_reader :code

    def initialize(code, message = nil)
      @code = code
      super("FileMaker Data API responded with error #{code}: #{message}")
    end
  end

  class UnknownError < APIError; end         # error code -1
  class ResourceMissingError < APIError; end # error codes 100..199
  class RecordMissingError < ResourceMissingError; end
  class AccountError < APIError; end         # error codes 200..299
  class LockError < APIError; end            # error codes 300..399
  class ParameterError < APIError; end       # error codes 400..499
  class ValidationError < APIError; end      # error codes 500..599
  class SystemError < APIError; end          # error codes 800..899
  class ScriptError < APIError; end          # error codes 1200..1299
  class ODBCError < APIError; end            # error codes 1400..1499
end

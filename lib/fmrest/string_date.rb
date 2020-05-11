# frozen_string_literal: true

require "date"

module FmRest
  # Gotchas:
  #
  # 1.
  #
  #   Date === <StringDate instance> # => false
  #
  # The above can affect case conditions, as trying to match a StringDate
  # with:
  #
  #   case obj
  #   when Date
  #     ...
  #
  # ...will not work.
  #
  # Instead one must specify the FmRest::StringDate class:
  #
  #   case obj
  #   when Date, FmRest::StringDate
  #     ...
  #
  # 2.
  #
  # StringDate#eql? only matches other strings, not dates.
  #
  # This could affect hash indexing when a StringDate is used as a key.
  #
  # TODO: Verify the above
  #
  # 3.
  #
  # StringDate#succ and StringDate#next return a String, despite Date#succ
  # and Date#next also existing.
  #
  # Workaround: Use StringDate#next_day or strdate + 1
  #
  # 4.
  #
  # StringDate#to_s returns the original string, not the Date string
  # representation.
  #
  # Workaround: Use strdate.to_date.to_s
  #
  # 5.
  #
  # StringDate#hash returns the hash for the string (important when using
  # a StringDate as a hash key)
  #
  # 6.
  #
  # StringDate#as_json returns the string
  #
  # Workaround: Use strdate.to_date.as_json
  #
  # 7.
  #
  # Equality with Date is not reciprocal:
  #
  #   str_date == date #=> true
  #   date == str_date #=> false
  #
  # NOTE: Potential workaround: Inherit StringDate from Date instead of String
  #
  # 8.
  #
  # Calling string transforming methods (e.g. .upcase) returns a StringDate
  # instead of a String.
  #
  # NOTE: Potential workaround: Inherit StringDate from Date instead of String
  #
  class StringDate < String
    DELEGATE_CLASS = ::Date

    class InvalidDate < ArgumentError; end

    class << self
      alias_method :strptime, :new
    end

    def initialize(str, date_format, **str_args)
      super(str, **str_args)

      begin
        @delegate = self.class::DELEGATE_CLASS.strptime(str, date_format)
      rescue ArgumentError
        raise InvalidDate
      end

      freeze
    end

    def is_a?(klass)
      klass == ::Date || super
    end
    alias_method :kind_of?, :is_a?

    def to_date
      @delegate
    end

    def to_datetime
      @delegate.to_datetime
    end

    def to_time
      @delegate.to_time
    end

    # ActiveSupport method
    def in_time_zone(*_)
      @delegate.in_time_zone(*_)
    end

    def inspect
      "#<#{self.class.name} #{@delegate.inspect} - #{super}>"
    end

    def <=>(oth)
      return @delegate <=> oth if oth.is_a?(::Date) || oth.is_a?(Numeric)
      super
    end

    def +(val)
      return @delegate + val if val.kind_of?(Numeric)
      super
    end

    def <<(val)
      return @delegate << val if val.kind_of?(Numeric)
      super
    end

    def ==(oth)
      return @delegate == oth if oth.kind_of?(::Date) || oth.kind_of?(Numeric)
      super
    end
    alias_method :===, :==

    def upto(oth, &blk)
      return @delegate.upto(oth, &blk) if oth.kind_of?(::Date) || oth.kind_of?(Numeric)
      super
    end

    def between?(a, b)
      return @delegate.between?(a, b) if [a, b].any? {|o| o.is_a?(::Date) || o.is_a?(Numeric) }
      super
    end

    private

    def respond_to_missing?(name, include_private = false)
      @delegate.respond_to?(name, include_private)
    end

    def method_missing(method, *args, &block)
      @delegate.send(method, *args, &block)
    end
  end

  class StringDateTime < StringDate
    DELEGATE_CLASS = ::DateTime

    def is_a?(klass)
      klass == ::DateTime || super
    end
    alias_method :kind_of?, :is_a?

    def to_date
      @delegate.to_date
    end

    def to_datetime
      @delegate
    end
  end
end

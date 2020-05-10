# frozen_string_literal: true

module FmRest
  module V1
    module Utils
      VALID_SCRIPT_KEYS = [:prerequest, :presort, :after].freeze

      FM_DATETIME_FORMAT_MATCHER = /MM|mm|dd|HH|ss|yyyy/.freeze

      FM_DATETIME_FORMAT_SUBSTITUTIONS = {
        "MM"   => "%m",
        "dd"   => "%d",
        "yyyy" => "%Y",
        "HH"   => "%H",
        "mm"   => "%M",
        "ss"   => "%S"
      }.freeze

      # Converts custom script options to a hash with the Data API's expected
      # JSON script format.
      #
      # If script_options is a string or symbol it will be passed as the name
      # of the script to execute (after the action, e.g. save).
      #
      # If script_options is an array the first element will be the name of the
      # script to execute (after the action) and the second element (if any)
      # will be its param value.
      #
      # If script_options is a hash it will expect to contain one or more of
      # the following keys: :prerequest, :presort, :after
      #
      # Any of those keys should contain either a string/symbol or array, which
      # will be treated as described above, except for their own script
      # execution order (prerequest, presort or after action).
      #
      # Examples:
      #
      #     convert_script_params("My Script")
      #     # => { "script": "My Script" }
      #
      #     convert_script_params(["My Script", "the param"])
      #     # => { "script": "My Script", "script.param": "the param" }
      #
      #     convert_script_params(after: "After Script", prerequest: "Prerequest Script")
      #     # => { "script": "After Script", "script.prerequest": "Prerequest Script" }
      #
      #     convert_script_params(presort: ["Presort Script", "foo"], prerequest: "Prerequest Script")
      #     # => {
      #     #      "script.presort": "After Script",
      #     #      "script.presort.param": "foo",
      #     #      "script.prerequest": "Prerequest Script"
      #     #    }
      #
      def convert_script_params(script_options)
        params = {}

        case script_options
        when String, Symbol
          params[:script] = script_options.to_s

        when Array
          params.merge!(convert_script_arguments(script_options))

        when Hash
          script_options.each_key do |key|
            next if VALID_SCRIPT_KEYS.include?(key)
            raise ArgumentError, "Invalid script option #{key.inspect}"
          end

          if script_options.has_key?(:prerequest)
            params.merge!(convert_script_arguments(script_options[:prerequest], :prerequest))
          end

          if script_options.has_key?(:presort)
            params.merge!(convert_script_arguments(script_options[:presort], :presort))
          end

          if script_options.has_key?(:after)
            params.merge!(convert_script_arguments(script_options[:after]))
          end
        end

        params
      end

      # Converts a FM date-time format to `Date.strptime` format
      #
      def convert_date_time_format(fm_format)
        fm_format.gsub(FM_DATETIME_FORMAT_MATCHER, FM_DATETIME_FORMAT_SUBSTITUTIONS)
      end

      private

      def convert_script_arguments(script_arguments, suffix = nil)
        base = suffix ? "script.#{suffix}".to_sym : :script

        {}.tap do |params|
          case script_arguments
          when String, Symbol
            params[base] = script_arguments.to_s
          when Array
            params[base] = script_arguments.first.to_s
            params["#{base}.param".to_sym] = script_arguments[1] if script_arguments[1]
          else
            raise ArgumentError, "Script arguments are expected as a String, Symbol or Array"
          end
        end
      end
    end
  end
end

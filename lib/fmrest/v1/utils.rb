# frozen_string_literal: true

module FmRest
  module V1
    module Utils
      VALID_SCRIPT_KEYS = [:prerequest, :presort, :after].freeze

      # See https://help.claris.com/en/pro-help/content/finding-text.html
      FM_FIND_OPERATORS_RE = /([@\*#\?!=<>"])/

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
      # @param script_options [String, Hash, Array] The script parameters to
      # convert to canonical form
      #
      # @return [Hash] The converted script parameters
      #
      # @example
      #   convert_script_params("My Script")
      #   # => { "script": "My Script" }
      #
      #   convert_script_params(["My Script", "the param"])
      #   # => { "script": "My Script", "script.param": "the param" }
      #
      #   convert_script_params(after: "After Script", prerequest: "Prerequest Script")
      #   # => { "script": "After Script", "script.prerequest": "Prerequest Script" }
      #
      #   convert_script_params(presort: ["Presort Script", "foo"], prerequest: "Prerequest Script")
      #   # => {
      #   #      "script.presort": "After Script",
      #   #      "script.presort.param": "foo",
      #   #      "script.prerequest": "Prerequest Script"
      #   #    }
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

      # Borrowed from `ERB::Util`
      #
      # This method is preferred to escape Data API URIs components over
      # `URI.encode_www_form_component` (and similar methods) because the
      # latter converts spaces to `+` instead of `%20`, which the Data API
      # doesn't seem to like.
      #
      # @param s [String] An URL component to encode
      # @return [String] The URL-encoded string
      def url_encode(s)
        s.to_s.b.gsub(/[^a-zA-Z0-9_\-.]/n) { |m|
          sprintf("%%%02X", m.unpack("C")[0])
        }
      end

      # Escapes FileMaker find operators from the given string in order to use
      # it in a find request.
      #
      # @param s [String] The string to escape
      # @return [String] A new string with find operators escaped with
      #   backslashes
      def escape_find_operators(s)
        s.gsub(FM_FIND_OPERATORS_RE, "\\\\\\1")
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

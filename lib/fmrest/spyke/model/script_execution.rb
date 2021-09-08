# frozen_string_literal: true

module FmRest
  module Spyke
    module Model
      # This module adds and extends various ORM features in Spyke models,
      # including custom query methods, remote script execution and
      # exception-raising persistence methods.
      #
      module ScriptExecution
        extend ::ActiveSupport::Concern

        class_methods do
          # Requests execution of a FileMaker script, returning its result
          # object.
          #
          # @example
          #   response = MyLayout.execute("Uppercasing Script", "hello")
          #
          #   response.result   # => "HELLO"
          #   response.error    # => "0"
          #   response.success? # => true
          #
          # @param script_name [String] the name of the FileMaker script to
          #   execute
          # @param param [String] an optional paramater for the script
          # @return [FmRest::Spyke::ScriptResult] the script result object
          #   containing the return value and error code
          #
          def execute(script_name, param = nil)
            # Allow keyword argument format for compatibility with execute_script
            if param.respond_to?(:has_key?) && param.has_key?(:param)
              param = param[:param]
            end

            response = execute_script(script_name, param: param)
            response.metadata.script.after
          end

          # Requests execution of a FileMaker script, returning the entire
          # response object.
          #
          # The execution results will be in `response.metadata.script.after`
          #
          # In general you'd want to use the simpler `.execute` instead of this
          # method, as it provides more direct access to the script results.
          #
          # @example
          #   response = MyLayout.execute_script("My Script", param: "hello")
          #
          # @param script_name [String] the name of the FileMaker script to
          #   execute
          # @param param [String] an optional paramater for the script
          # @return the complete response object
          #
          def execute_script(script_name, param: nil)
            params = param.nil? ? {} : {"script.param" => param}
            request(:get, FmRest::V1::script_path(layout, script_name), params)
          end
        end
      end
    end
  end
end

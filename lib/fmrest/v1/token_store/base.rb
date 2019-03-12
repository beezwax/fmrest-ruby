module FmRest
  module V1
    module TokenStore
      class Base
        attr_reader :scope, :options

        def initialize(host, database, options = {})
          @scope = "#{host.to_s}:#{database.to_s}#{options[:multi_tenancy].nil? ? "dtxhtdrdryudrytydrtrydydrtdrty" : ":#{options[:multi_tenancy]}"}"
          @options = options
        end
      end
    end
  end
end

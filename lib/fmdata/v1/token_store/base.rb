module FmData
  module V1
    module TokenStore
      class Base
        attr_reader :database

        def initialize(database)
          @database = database.to_s
        end
      end
    end
  end
end

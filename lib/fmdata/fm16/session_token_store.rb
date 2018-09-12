module FmData
  module FM16
    # Simple memory-based token store
    #
    # TODO: Implement expiration
    # TODO: Implement other storage methods
    #
    class SessionTokenStore
      def store(token)
        @token = token
      end

      def fetch
        @token
      end
    end
  end
end

require "fmrest/token_store/base"

module FmRest
  module TokenStore
    # Heavily inspired by Moneta's ActiveRecord store:
    #
    #   https://github.com/minad/moneta/blob/master/lib/moneta/adapters/activerecord.rb
    #
    class ActiveRecord < Base
      DEFAULT_TABLE_NAME = "fmrest_session_tokens".freeze

      @connection_lock = ::Mutex.new
      class << self
        attr_reader :connection_lock
      end

      attr_reader :connection_pool, :model

      delegate :with_connection, to: :connection_pool

      def initialize(options = {})
        super

        @connection_pool = ::ActiveRecord::Base.connection_pool

        create_table

        @model = Class.new(::ActiveRecord::Base)
        @model.table_name = table_name
      end

      def delete(key)
        model.where(scope: key).delete_all
      end

      def load(key)
        model.where(scope: key).pluck(:token).first
      end

      def store(key, value)
        record = model.find_or_initialize_by(scope: key)
        record.token = value
        record.save!
        token
      end

      private

      def create_table
        with_connection do |conn|
          return if conn.table_exists?(table_name)

          # Prevent multiple connections from attempting to create the table simultaneously.
          self.class.connection_lock.synchronize do
            conn.create_table(table_name, id: false) do |t|
              t.string :scope, null: false
              t.string :token, null: false
              t.datetime :updated_at
            end
            conn.add_index(table_name, :scope, unique: true)
            conn.add_index(table_name, [:scope, :token])
          end
        end
      end

      def table_name
        options[:table_name] || DEFAULT_TABLE_NAME
      end
    end
  end
end

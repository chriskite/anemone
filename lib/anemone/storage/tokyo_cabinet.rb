require 'rufus-tokyo'
require 'forwardable'

module Anemone
  module Storage
    class TokyoCabinet
      extend Forwardable

      def_delegators :@db, :close, :merge!, :size, :keys

      def initialize(*args)
        @db = Rufus::Tokyo::Cabinet.new(*args)
        @db.clear
      end

      def [](key)
        Marshal.load @db[key]
      end

      def []=(key, value)
        @db[key] = Marshal.dump value
      end

      def has_key?(key)
        !@db[key].nil?
      end

      def delete(key)
        Marshal.load @db.delete(key)
      end

      def values
        @db.values.map { |v| Marshal.load v }
      end

    end
  end
end

require 'rufus-tokyo'

module Anemone
  module Storage
    class TokyoCabinet

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

      def keys
        @db.keys
      end

      def values
        @db.values.map { |v| Marshal.load v }
      end

      def method_missing(symbol, *args)
        @db.send(symbol, *args)
      end

    end
  end
end

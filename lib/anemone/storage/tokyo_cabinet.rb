require 'rufus-tokyo'

module Anemone
  module Storage
    class TokyoCabinet

      def initialize(file)
        @store = Rufus::Tokyo::Cabinet.new(file)
        @store.clear
      end

      def [](key)
        Marshal.load(@store[key])
      end

      def []=(key, value)
        @store[key] = Marshal.dump(value)
      end

      def has_key?(key)
        @store.keys(:prefix => key).include? key
      end

      def method_missing(symbol, *args)
        @store.send(symbol, *args)
      end

    end
  end
end

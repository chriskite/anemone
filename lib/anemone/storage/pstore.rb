require 'pstore'
require 'forwardable'

module Anemone
  module Storage
    class PStore
      extend Forwardable

      def_delegators :@keys, :has_key?, :keys, :size

      def initialize(file, remove_existing = false)
        if File.exists?(file) && remove_existing
          File.delete(file) 
        end
        
        @store = ::PStore.new(file)
        @keys = {}
      end

      def [](key)
        @store.transaction { |s| s[key] }
      end

      def []=(key,value)
        @keys[key] = nil
        @store.transaction { |s| s[key] = value }
      end

      def delete(key)
        @keys.delete(key)
        @store.transaction { |s| s.delete key}
      end

      def each
        @keys.each_key do |key|
          value = nil
          @store.transaction { |s| value = s[key] }
          yield key, value
        end
      end

      def merge!(hash)
        @store.transaction do |s|
          hash.each { |key, value| s[key] = value; @keys[key] = nil }
        end
        self
      end

      def non_fetched_urls(limit = 10)
        raise GenericError, $!
      end

      def close; end

    end
  end
end

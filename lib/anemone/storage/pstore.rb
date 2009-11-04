require 'pstore'

module Anemone
  module Storage
    class PStore

      def initialize(file)
        File.delete(file) if File.exists?(file)
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

      def has_key?(key)
        @keys.has_key? key
      end

      def delete(key)
        @keys.delete(key)
        @store.transaction { |s| s.delete key}
      end

      def values
        @store.transaction do |s|
          s.roots.map { |root| s[root] }
        end
      end

      def keys
        @keys.keys
      end

      def set_keys_nil keys
        @store.transaction do |s|
          keys.each { |key| s[key] = nil; @keys[key] = nil }
        end
      end

    end
  end
end

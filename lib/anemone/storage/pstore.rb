require 'pstore'

module Anemone
  module Storage
    class PStore

      def initialize(file)
        @store = ::PStore.new(file)
      end

      def [](key)
        @store.transaction { |s| s[key] }
      end

      def []=(key,value)
        @store.transaction { |s| s[key] = value }
      end

      def has_key?(key)
        @store.transaction { |s| s.root? key}
      end

      def delete(key)
        @store.transaction { |s| s.delete key}
      end

      def values
        @store.transaction do |s|
          s.roots.map { |root| s[root] }
        end
      end

      def keys
         @store.transaction { |s| s.roots }
      end

    end
  end
end

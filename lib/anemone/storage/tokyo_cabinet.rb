begin
  require "rufus/tokyo"
rescue LoadError
  puts "You need the rufus-tokyo gem to use Anemone::Storage::TokyoCabinet"
  exit
end

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
        if value = @db[key]
          load_value(value)
        end
      end

      def []=(key, value)
        @db[key] = [Marshal.dump(value)].pack("m")
      end

      def has_key?(key)
        !!@db[key]
      end

      def delete(key)
        if value = @db.delete(key)
          load_value(value)
        end
      end

      def values
        @db.values.map { |v| load_value(v) }
      end

      private

      def load_value(value)
        Marshal.load(value.unpack("m")[0])
      end
      
    end
  end
end

begin
  require 'tokyocabinet'
rescue LoadError
  puts "You need the tokyocabinet gem to use Anemone::Storage::TokyoCabinet"
  exit
end

require 'forwardable'

module Anemone
  module Storage
    class TokyoCabinet
      extend Forwardable

      def_delegators :@db, :close, :size, :keys, :has_key?

      def initialize(file, remove_existing = false)
        raise "TokyoCabinet filename must have .tch extension" if File.extname(file) != '.tch'
        @db = ::TokyoCabinet::HDB::new
        if remove_existing 
          @db.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OTRUNC)
        else
          @db.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
        end
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

      def delete(key)
        value = self[key]
        @db.delete(key)
        value
      end

      def each
        @db.each { |k, v| yield k, load_value(v) }
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      private

      def load_value(value)
        Marshal.load(value.unpack("m")[0])
      end

    end
  end
end

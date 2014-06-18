begin
  require 'aws-sdk'
rescue LoadError
  puts "You need the sqlite3 gem to use Anemone::Storage::SQLite3"
  exit
end

module Anemone
  module Storage
    class S3

      def initialize(bucket,key,secret)
        AWS.config(
          :access_key_id => ENV['AWS_ACCESS_KEY']',
          :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
        )
        @s3 = AWS::S3.new
        @bucket = @s3.buckets[bucket]
      end

      def [](url)
        @bucket.objects[url2hash(url)].read
      end

      def []=(url, value)
        object = @bucket.objects[url2hash(url)]
        object.write(value)
      end

      def delete(url)
        @bucket.objects.delete(url2hash(url))
      end

      def each
        #TODO
      end

      def merge!(hash)
        #TODO
      end

      def size
        #TODO
      end

      def keys
        #TODO
      end

      def has_key?(url)
        #TODO
      end

      def close
        #TODO
      end

      private
      
      def url2hash(url)
        Digest::SHA1.digest(url)
      end
    end
  end
end


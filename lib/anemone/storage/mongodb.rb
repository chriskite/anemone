begin
  require 'mongo'
rescue LoadError
  puts "You need the mongo gem to use Anemone::Storage::MongoDB"
  exit
end

module Anemone
  module Storage
    class MongoDB 

      def initialize(mongo_db, collection_name)
        @db = mongo_db
        @collection = @db[collection_name]
        @collection.remove
        @collection.create_index 'url'
      end

      def [](url)
        if value = @collection.find_one('url' => url.to_s)
          load_page(value)
        end
      end

      def []=(url, page)
        @collection.update(
          {'url' => page.url.to_s},
          page.to_hash,
          :upsert => true
        )
      end

      def delete(url)
        page = self[url]
        @collection.remove('url' => url.to_s)
        page
      end

      def each
        @collection.find do |cursor|
          cursor.each do |doc|
            page = load_page(doc)
            yield page.url.to_s, page 
          end
        end
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      def size
        @collection.count
      end

      def keys
        keys = []
        self.each { |k, v| keys << k.to_s }
        keys
      end

      def has_key?(url)
        !!@collection.find_one('url' => url.to_s)
      end

      def close
        @db.connection.close
      end

      private

      def load_page(hash)
        Page.from_hash(hash)
      end

    end
  end
end


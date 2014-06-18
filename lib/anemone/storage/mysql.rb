begin
  require 'mysql2'
rescue LoadError
  puts "You need the mysql2 gem to use Anemone::Storage::MySQL"
  exit
end

module Anemone
  module Storage
    class MySQL

      def initialize(opts = {})
        @db = Mysql2::Client.new(:host => "localhost", :username => "crawler", :password => "anemone_pass", :database => "anemone")
        create_schema
      end

      def [](url)
        value = @db.get_first_value('SELECT data FROM anemone_storage WHERE page_key = ?', url.to_s)
        if value
          Marshal.load(value)
        end
      end

      def []=(url, value)
        data = Marshal.dump(value)
        if has_key?(url)
          @db.execute('UPDATE anemone_storage SET page_data = ? WHERE page_key = ?', data, url.to_s)
        else
          @db.execute('INSERT INTO anemone_storage (page_data, page_key) VALUES(?, ?)', data, url.to_s)
        end
      end

      def delete(url)
        page = self[url]
        @db.execute('DELETE FROM anemone_storage WHERE page_key = ?', url.to_s)
        page
      end

      def each
        @db.execute("SELECT page_key, page_data FROM anemone_storage ORDER BY id") do |row|
          value = Marshal.load(row[1])
          yield row[0], value
        end
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      def size
        @db.get_first_value('SELECT COUNT(id) FROM anemone_storage')
      end

      def keys
        @db.execute("SELECT page_key FROM anemone_storage ORDER BY id").map{|t| t[0]}
      end

      def has_key?(url)
        !!@db.get_first_value('SELECT id FROM anemone_storage WHERE page_key = ?', url.to_s)
      end

      def close
        @db.close
      end

      private
      
      def create_schema
        @db.query <<SQL
          create table if not exists anemone_storage (
            id int(11) NOT NULL auto_increment,
            page_key varchar(255),
            page_data BLOB,
            PRIMARY KEY (id),
            key (page_key)
          ) DEFAULT CHARSET=utf8;
SQL
      end

      def load_page(hash)
        BINARY_FIELDS.each do |field|
          hash[field] = hash[field].to_s
        end
        Page.from_hash(hash)
      end

    end
  end
end


# coding: utf-8

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
        host = opts[:host] || 'localhost'
        username = opts[:username] || 'crawler'
        password = opts[:password] || 'anemone_pass'
        database = opts[:database] || 'anemone'
        @db = Mysql2::Client.new(:host => #{host}, :username => #{username}, :password => #{password}, :database => #{database})
        create_schema
      end

      def [](url)
        value = @db.query("SELECT data FROM anemone_storage WHERE page_key = '#{get_hash_value(url)}'").first['data']
        if value
          Marshal.load(value)
        end
      end

      def []=(url, value)
        data = Marshal.dump(value)
        key = get_hash_value(url)
        if has_key?(url)
          @db.query("UPDATE anemone_storage SET page_data = '#{data}' WHERE page_key = '#{key}'")
        else
          @db.query("INSERT INTO anemone_storage (page_key, page_data) VALUES('#{key}', '#{data}')")
        end
      end

      def delete(url)
        page = self[url]
        @db.query("DELETE FROM anemone_storage WHERE page_key = '#{get_hash_value(url)}'")
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
        @db.query('SELECT COUNT(*) FROM anemone_storage')
      end

      def keys
        @db.query("SELECT page_key FROM anemone_storage ORDER BY id").map{|t| t[0]}
      end

      def has_key?(url)
        key = get_hash_value(url)
        result = @db.query("SELECT count(id) FROM anemone_storage WHERE page_key = '#{key}'")
        if result.first['count(id)'] > 0
          return true
        else
          return false
        end
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

      def get_hash_value(key)
        Digest::SHA1.hexdigest(key)
      end
    end
  end
end


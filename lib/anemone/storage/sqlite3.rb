begin
  require 'sqlite3'
  require 'json'
rescue LoadError
  puts "You need the sqlite3 and json gem to use Anemone::Storage::SQLite3"
  exit
end

module Anemone
  module Storage
    class SQLite3

      TABLE_NAME = "pages"

      def initialize(opts = {})
        @db_path = opts[:db] || "storage.db"
        @db = ::SQLite3::Database.new(@db_path)
        make_sure_table_created
      end

      def close
        @db.close
      end

      def [](url)
        data = @db.get_first_value("select page from #{TABLE_NAME} where url=?", url)
        load_page(data)
      end

      def []=(url, page)
        data = page.to_hash.to_json
        if has_key?(url)
          @db.execute("update #{TABLE_NAME} set page = ? where url = ?", data, url)
        else
          @db.execute("insert into #{TABLE_NAME}(url, page) values(?, ?)", url, data)
        end
      end

      def delete(url)
        page = self[url]
        @db.execute("delete from #{TABLE_NAME} where url=?", url) if page
        page
      end

      def each(&block)
        each0 &block
      end

      def keys
        keys = []
        each0(:url_only => true) { |k, v| keys << k.to_s }
        keys
      end

      def has_key?(url)
        sql = "select url from #{TABLE_NAME} where url =?"
        !! @db.get_first_value(sql, url)
      end

      def merge!(hash)
        hash.each do |key, value|
          self[key] = value
        end
        self
      end

      def size
        @db.get_first_value("select count(*) from #{TABLE_NAME}")
      end

      private
      def make_sure_table_created
        schema = <<-SQL
        create table if not exists #{TABLE_NAME}(
          id integer primary key autoincrement,
          url varchar(4096) unique,
          page text
        )
        SQL
        @db.execute(schema)
      end

      def each0(opts = {}, &block)
        min, max = @db.get_first_row("select min(id), max(id) from #{TABLE_NAME}")
        return unless min
        current = min
        url_only = !! opts[:url_only]
        columns = url_only ? "url" : "url, page"
        sql = "select #{columns} from #{TABLE_NAME} where id >= ? and id < ? order by id asc"
        stmt = @db.prepare(sql)
        batch = 100
        while current <= max
          stmt.bind_params(current, current + batch)
          stmt.execute do |result|
            result.each do |row|
              url, page = row
              page = load_page(page) unless url_only
              p url
              p page
              yield url, page
            end
          end
          current += batch
        end
      ensure
        stmt.close if stmt
      end


      def load_page(data)
        return unless data
        Page.from_hash(JSON.parse(data))
      end
    end
  end
end

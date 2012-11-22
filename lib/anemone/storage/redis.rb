require 'redis'

module Anemone
  module Storage
    class Redis

      MARSHAL_FIELDS = %w(links visited fetched)
      DOZEN_HOURS = 43200

      def initialize(opts = {})
        @redis = ::Redis.new(opts)
        @key_prefix = opts[:key_prefix] || 'anemone'
        @expiration = opts[:key_expiration] || DOZEN_HOURS
        keys.each { |key| delete(key) }
      end

      def [](key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        rget(rkey)
      end

      def []=(key, value)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        hash = value.to_hash
        MARSHAL_FIELDS.each do |field|
          hash[field] = Marshal.dump(hash[field])
        end
        key_vals = []
        hash.each do |field, value|
          key_vals += [field, value]
        end
        @redis.hmset(rkey, key_vals)
        @redis.expire(rkey, @expiration)
      end

      def delete(key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        page = self[key]
        @redis.del(rkey)
        page
      end

      def each
        rkeys = @redis.keys("#{@key_prefix}:pages:*")
        rkeys.each do |rkey|
          page = rget(rkey)
          yield page.url.to_s, page
        end
      end

      def merge!(hash)
        hash.each { |key, value| self[key] = value }
        self
      end

      def size
        @redis.keys("#{@key_prefix}:pages:*").size
      end

      def keys
        keys = []
        self.each { |k, v| keys << k.to_s }
        keys
      end

      def has_key?(key)
        rkey = "#{@key_prefix}:pages:#{key.to_s}"
        @redis.exists(rkey)
      end

      def close
        @redis.quit
      end

      private

      def load_value(hash)
        MARSHAL_FIELDS.each do |field|
          unless hash[field].nil? || hash[field] == ''
            hash[field] = Marshal.load(hash[field]) 
          end
        end
        Page.from_hash(hash)
      end

      def rget(rkey)
        hash = @redis.hgetall(rkey)
        if !!hash
          load_value(hash)
        end
      end

    end
  end
end

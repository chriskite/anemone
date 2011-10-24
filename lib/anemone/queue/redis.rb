begin
  require 'redis'
rescue LoadError
  puts "You need the redis-client gem to use Anemone::Queue::Redis"
  exit
end

module Anemone
  module Queue
    class Redis

      def initialize(queue_type, opts = {})
        if [:link, :page].include? !queue_type
          raise 'You must specify a queue type (:link or :page)'
        end
        @redis = ::Redis.new(opts)
        @prefix = "#{opts[:key_prefix] || 'anemone'}:#{queue_type}"
        clear
      end

      def <<(job)
        id = @redis.incr("#{@prefix}:counter")
        job.each { |k,v| @redis.hset("#{@prefix}:#{id}", k, v) }
      end

      def deq
        key = keys.last
        val = rget(key)
        @redis.del(key)
        val
      end

      def empty?
        keys.count == 0
      end

      def size
        keys.count
      end

      def num_waiting
        keys.count
      end

      def clear
        keys.each { |key| @redis.del(key) }
        @redis.del("#{@prefix}:counter")
      end

      private

      def each
        keys.each { |key| yield rget(key) }
      end

      def keys
        @redis.keys("#{@prefix}:*").select {|key| key != "#{@prefix}:counter"}
      end

      def rget(key)
        @redis.hkeys(key).inject({}) do |hash, rkey|
          hash[rkey] = @redis.hget(key, rkey)
          hash
        end
      end

    end
  end
end
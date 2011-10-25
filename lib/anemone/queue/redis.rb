begin
  require 'redis'
rescue LoadError
  puts "You need the redis-client gem to use Anemone::Queue::Redis"
  exit
end

module Anemone
  module Queue
    class Redis

      def initialize(opts = {})
        @redis = ::Redis.new(opts)
        @list = "#{opts[:key_prefix] || 'anemone'}:#{self.hash.abs}"
        @waiting = "#{@list}:waiting"
        @timeout = opts[:timeout] || 60
        clear
      end

      def <<(job)
        @redis.lpush(@list,job.to_json)
      end

      def deq
        @redis.incr(@waiting)
        json = @redis.brpop(@list, @timeout)
        @redis.decr(@waiting)
        JSON.parse(json.last) rescue nil
      end

      def empty?
        size == 0
      end

      def size
        @redis.llen(@list)
      end

      def num_waiting
        @redis.get(@waiting).to_i
      end

      def clear
        @redis.del(@list, @waiting)
      end

    end
  end
end
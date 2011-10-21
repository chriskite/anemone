begin
  require 'redis-client'
rescue LoadError
  puts "You need the redis-client gem to use Anemone::Queue::Redis"
  exit
end

module Anemone
  module Queue
    class Redis

      def initialize
        #TODO
      end

      def <<
        #TODO
      end

      def deq
        #TODO
      end

      def empty?
        #TODO
      end

      def size
        #TODO
      end

      def num_waiting
        #TODO
      end

      def clear
        #TODO
      end

    end
  end
end
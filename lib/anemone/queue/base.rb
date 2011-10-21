require 'anemone/queue/exceptions'

module Anemone
  module Queue
    class Base

      def initialize(adapter)
        @adap = adapter

        # verify adapter conforms to this class's methods
        methods.each do |method|
          if !@adap.respond_to?(method.to_sym)
            raise "Queue adapter must support method #{method}"
          end
        end
      end

      def <<(val)
        @adap << val rescue raise InsertionError, $!
      end

      def deq
        @adap.deq rescue raise RetrievalError, $!
      end

      def empty?
        @adap.empty rescue raise GenericError, $!
      end

      def size
        @adap.size rescue raise GenericError, $!
      end

      def num_waiting
        @adap.num_waiting rescue raise GenericError, $!
      end

      def clear
        @adap.clear rescue raise GenericError, $!
      end

    end
  end
end
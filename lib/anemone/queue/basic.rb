module Anemone
  module Queue
    class Basic < DelegateClass ::Queue

      def initialize
        super ::Queue.new
      end

    end
  end
end
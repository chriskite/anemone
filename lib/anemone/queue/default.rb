module Anemone
  module Queue
    class Default < DelegateClass ::Queue

      def initialize
        super ::Queue.new
      end

    end
  end
end
module Anemone
  module Queue
    class Default < DelegateClass ::Queue

      def initialize(queue_type, opts = {})
        super ::Queue.new
      end

    end
  end
end
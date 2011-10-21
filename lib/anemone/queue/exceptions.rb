module Anemone
  module Queue

    class GenericError < Error; end

    class ConnectionError < Error; end

    class RetrievalError < Error; end

    class InsertionError < Error; end

    class CloseError < Error; end

  end
end
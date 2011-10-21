module Anemone
  class Queue

    def self.Default(*args)
      require 'anemone/queue/default'
      Default.new(*args)
    end

    def self.Redis(*args)
      require 'anemone/queue/redis'
      Redis.new(*args)
    end

  end
end
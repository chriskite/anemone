module Anemone
  module Queue

    def self.Default(*args)
      require 'anemone/queue/default'
      self::Default.new(*args)
    end

    def self.Redis(*args)
      require 'anemone/queue/redis'
      self::Redis.new(*args)
    end

  end
end
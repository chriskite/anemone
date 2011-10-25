module Anemone
  module Queue

    def self.Basic(*args)
      require 'anemone/queue/basic'
      self::Basic.new(*args)
    end

    def self.Redis(*args)
      require 'anemone/queue/redis'
      self::Redis.new(*args)
    end

  end
end
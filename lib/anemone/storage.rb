module Anemone
  module Storage

    def self.Hash(*args)
      Hash.new(*args)
    end

    def self.PStore(*args)
      require 'anemone/storage/pstore'
      self::PStore.new(*args)
    end

    def self.TokyoCabinet(*args)
      require 'anemone/storage/tokyo_cabinet'
      self::TokyoCabinet.new(*args)
    end

  end
end

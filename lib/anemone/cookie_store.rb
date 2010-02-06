require 'forwardable'

module Anemone
  class CookieStore
    extend Forwardable

    def_delegators :@cookies, :empty?

    attr_reader :cookies

    def initialize(cookies = nil)
      @cookies = cookies || {}
    end

    def merge!(set_cookie_str)
      return unless !!set_cookie_str && set_cookie_str.index('=')
      cookie_hash = set_cookie_str.split(';').inject({}) do |acc, pair|
        key, value = pair.strip.split('=')
        acc[key] = value if key
      end
      @cookies.merge! cookie_hash
    end

    def to_s
      @cookies.map { |name, value| "#{name}=#{value}" }.join(';')
    end

  end
end

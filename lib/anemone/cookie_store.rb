module Anemone
  class CookieStore < Hash

    def initialize(cookies = nil)
      super
      cookies.each { |key, value| self[key] = value } if cookies
    end

    def merge!(set_cookie_str)
      return unless !!set_cookie_str && set_cookie_str.index('=')
      cookie_hash = set_cookie_str.split(';').inject({}) do |acc, pair|
        key, value = pair.strip.split('=')
        acc[key] = value if key
      end
      super(cookie_hash)
    end

    def to_s
      self.map { |name, value| "#{name}=#{value}" }.join(';')
    end

  end
end

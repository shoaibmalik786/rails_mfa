# frozen_string_literal: true

module RailsMFA
  class Configuration
    attr_accessor :sms_provider, :email_provider, :token_store, :code_expiry_seconds, :code_length

    def initialize
      # These lambdas are defined by the host app
      @sms_provider = nil   # -> lambda: ->(to, message) { ... }
      @email_provider = nil # -> lambda: ->(to, subject, body) { ... }

      # Use Rails.cache by default if Rails is loaded
      @token_store = defined?(Rails) && Rails.respond_to?(:cache) ? Rails.cache : SimpleStore.new

      @code_expiry_seconds = 300 # 5 minutes
      @code_length = 6
    end
  end

  # Fallback in case Rails.cache is unavailable (for plain Ruby apps)
  class SimpleStore
    def initialize
      @store = {}
    end

    def write(key, value, expires_in: nil)
      @store[key] = { value: value, expires_at: expires_in ? Time.now + expires_in : nil }
    end

    def read(key)
      entry = @store[key]
      return nil unless entry
      return nil if entry[:expires_at] && Time.now > entry[:expires_at]

      entry[:value]
    end

    def delete(key)
      @store.delete(key)
    end
  end
end

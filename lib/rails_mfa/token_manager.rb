# frozen_string_literal: true

require "securerandom"
require "active_support/security_utils"

module RailsMFA
  class TokenManager
    def initialize(store: RailsMFA.configuration.token_store)
      @store = store
    end

    def generate_numeric_code(user_id, length: RailsMFA.configuration.code_length,
                              expiry: RailsMFA.configuration.code_expiry_seconds)
      min = 10**(length - 1)
      max = (10**length) - 1
      code = rand(min..max).to_s
      @store.write(cache_key(user_id), code, expires_in: expiry)
      code
    end

    def verify_numeric_code(user_id, code)
      stored = @store.read(cache_key(user_id))
      return false unless stored

      valid = ActiveSupport::SecurityUtils.secure_compare(stored.to_s, code.to_s)
      @store.delete(cache_key(user_id)) if valid # one-time use
      valid
    end

    private

    def cache_key(user_id)
      "rails_mfa:otp:#{user_id}"
    end
  end
end

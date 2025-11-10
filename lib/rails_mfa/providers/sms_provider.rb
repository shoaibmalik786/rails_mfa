# frozen_string_literal: true

module RailsMFA
  module Providers
    # Example: host app can create a provider class that implements send_sms
    class SmsProvider < Base
      def initialize(&block)
        @block = block
      end

      def send_sms(to, message)
        @block.call(to, message)
      end
    end
  end
end

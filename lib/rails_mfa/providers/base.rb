# frozen_string_literal: true

module RailsMFA
  module Providers
    class Base
      def send_sms(to, message)
        raise NotImplementedError, "Implement send_sms in provider"
      end

      def send_email(to, subject, body)
        raise NotImplementedError, "Implement send_email in provider"
      end
    end
  end
end

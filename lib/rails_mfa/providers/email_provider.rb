# frozen_string_literal: true

module RailsMFA
  module Providers
    class EmailProvider < Base
      def initialize(&block)
        @block = block
      end

      def send_email(to, subject, body)
        @block.call(to, subject, body)
      end
    end
  end
end

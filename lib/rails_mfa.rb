# frozen_string_literal: true

require_relative "rails_mfa/version"
require_relative "rails_mfa/configuration"
require_relative "rails_mfa/token_manager"
require_relative "rails_mfa/model"
require_relative "rails_mfa/providers/base"
require_relative "rails_mfa/providers/sms_provider"
require_relative "rails_mfa/providers/email_provider"

module RailsMFA
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end
  end
end

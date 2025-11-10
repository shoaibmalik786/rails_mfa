# frozen_string_literal: true
require 'active_support/concern'
require 'rotp'
require 'rqrcode'

module RailsMFA
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def enable_mfa_for(*methods)
        class_attribute :rails_mfa_methods, instance_accessor: false
        self.rails_mfa_methods = methods.map(&:to_sym)
      end
    end

    def generate_totp_secret!
      secret = ROTP::Base32.random_base32
      # host app should store secret encrypted in a column like :mfa_secret
      self.update!(mfa_secret: secret) if respond_to?(:update!)
      secret
    end

    def totp_provisioning_uri(issuer: "RailsMFA")
      raise "No mfa_secret present" unless respond_to?(:mfa_secret) && mfa_secret
      ROTP::TOTP.new(mfa_secret, issuer: issuer).provisioning_uri(self.respond_to?(:email) ? email : "user")
    end

    def verify_totp(code)
      return false unless respond_to?(:mfa_secret) && mfa_secret
      totp = ROTP::TOTP.new(mfa_secret)
      totp.verify(code, drift_behind: 30)
    end

    def send_numeric_code(via: :sms)
      tm = TokenManager.new
      code = tm.generate_numeric_code(id)
      case via.to_sym
      when :sms
        raise "sms_provider not configured" unless RailsMFA.configuration.sms_provider
        RailsMFA.configuration.sms_provider.call(phone_number_for_sms, "Your verification code is: #{code}")
      when :email
        raise "email_provider not configured" unless RailsMFA.configuration.email_provider
        RailsMFA.configuration.email_provider.call(email, "Your verification code", "Code: #{code}")
      else
        raise "Unsupported channel"
      end
      code
    end

    def verify_numeric_code(code)
      tm = TokenManager.new
      tm.verify_numeric_code(id, code)
    end

    private

    def phone_number_for_sms
      # host app should implement proper phone number attribute
      respond_to?(:phone) ? phone : raise("Define phone attribute or override phone_number_for_sms")
    end
  end
end

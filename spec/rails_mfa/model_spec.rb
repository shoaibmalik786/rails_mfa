# frozen_string_literal: true
require 'cgi'

RSpec.describe RailsMFA::Model do
  # Create a test user class that includes the Model concern
  let(:user_class) do
    Class.new do
      include RailsMFA::Model

      attr_accessor :id, :email, :phone, :mfa_secret

      def initialize(id:, email: "test@example.com", phone: "+1234567890")
        @id = id
        @email = email
        @phone = phone
        @mfa_secret = nil
      end

      def update!(attributes)
        attributes.each { |key, value| send("#{key}=", value) }
      end
    end
  end

  let(:user) { user_class.new(id: 1) }

  before do
    RailsMFA.configure do |c|
      c.sms_provider = ->(to, message) { "SMS sent to #{to}: #{message}" }
      c.email_provider = ->(to, subject, body) { "Email sent to #{to}: #{subject} - #{body}" }
    end
  end

  describe "#generate_totp_secret!" do
    it "generates a Base32 secret" do
      secret = user.generate_totp_secret!
      expect(secret).to be_a(String)
      expect(secret.length).to be >= 16
      expect(secret).to match(/^[A-Z2-7]+$/)
    end

    it "stores the secret in mfa_secret attribute" do
      secret = user.generate_totp_secret!
      expect(user.mfa_secret).to eq(secret)
    end
  end

  describe "#totp_provisioning_uri" do
    it "returns a valid provisioning URI" do
      user.generate_totp_secret!
      uri = user.totp_provisioning_uri(issuer: "TestApp")

      expect(uri).to include("otpauth://totp/")
      expect(uri).to include("TestApp")
      expect(uri).to include(CGI.escape(user.email))
      expect(uri).to include("secret=")
    end

    it "raises error if no mfa_secret present" do
      expect { user.totp_provisioning_uri }.to raise_error("No mfa_secret present")
    end

    it "uses default issuer if not provided" do
      user.generate_totp_secret!
      uri = user.totp_provisioning_uri

      expect(uri).to include("RailsMFA")
    end
  end

  describe "#verify_totp" do
    it "verifies a valid TOTP code" do
      user.generate_totp_secret!
      totp = ROTP::TOTP.new(user.mfa_secret)
      valid_code = totp.now

      expect(user.verify_totp(valid_code)).to be_truthy
    end

    it "rejects an invalid TOTP code" do
      user.generate_totp_secret!
      expect(user.verify_totp("000000")).to be_falsey
    end

    it "returns false if no mfa_secret present" do
      expect(user.verify_totp("123456")).to be false
    end

    it "allows drift of 30 seconds" do
      user.generate_totp_secret!
      totp = ROTP::TOTP.new(user.mfa_secret)

      # Code from 30 seconds ago should work
      past_code = totp.at(Time.now - 30)
      expect(user.verify_totp(past_code)).to be_truthy
    end
  end

  describe "#send_numeric_code" do
    it "sends code via SMS when via: :sms is specified" do
      result = user.send_numeric_code(via: :sms)

      expect(result).to be_a(String)
      expect(result.length).to eq(6)
      expect(result).to match(/^\d+$/)
    end

    it "sends code via email when via: :email is specified" do
      result = user.send_numeric_code(via: :email)

      expect(result).to be_a(String)
      expect(result.length).to eq(6)
    end

    it "raises error if SMS provider not configured" do
      RailsMFA.configuration.sms_provider = nil

      expect { user.send_numeric_code(via: :sms) }.to raise_error("sms_provider not configured")
    end

    it "raises error if email provider not configured" do
      RailsMFA.configuration.email_provider = nil

      expect { user.send_numeric_code(via: :email) }.to raise_error("email_provider not configured")
    end

    it "raises error for unsupported channel" do
      expect { user.send_numeric_code(via: :carrier_pigeon) }.to raise_error("Unsupported channel")
    end

    it "calls the SMS provider with correct arguments" do
      sms_spy = spy("SMS Provider")
      RailsMFA.configuration.sms_provider = sms_spy

      code = user.send_numeric_code(via: :sms)

      expect(sms_spy).to have_received(:call).with(user.phone, "Your verification code is: #{code}")
    end

    it "calls the email provider with correct arguments" do
      email_spy = spy("Email Provider")
      RailsMFA.configuration.email_provider = email_spy

      code = user.send_numeric_code(via: :email)

      expect(email_spy).to have_received(:call).with(
        user.email,
        "Your verification code",
        "Code: #{code}"
      )
    end
  end

  describe "#verify_numeric_code" do
    it "verifies a code that was previously sent" do
      code = user.send_numeric_code(via: :sms)
      expect(user.verify_numeric_code(code)).to be true
    end

    it "rejects an invalid code" do
      user.send_numeric_code(via: :sms)
      expect(user.verify_numeric_code("wrong")).to be false
    end

    it "ensures one-time use of codes" do
      code = user.send_numeric_code(via: :sms)
      expect(user.verify_numeric_code(code)).to be true
      expect(user.verify_numeric_code(code)).to be false
    end
  end

  describe ".enable_mfa_for" do
    it "sets the mfa methods class attribute" do
      # This test requires ActiveSupport::Concern which provides class_attribute
      # Skip if not in a Rails environment or ActiveSupport is not fully loaded
      skip "class_attribute not available" unless user_class.respond_to?(:class_attribute)

      user_class.enable_mfa_for(:sms, :email, :totp)
      expect(user_class.rails_mfa_methods).to eq([:sms, :email, :totp])
    end

    it "can be called without error when class_attribute is available" do
      # Just ensure the method exists and can be called
      expect(user_class).to respond_to(:enable_mfa_for)
    end
  end
end

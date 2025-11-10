# frozen_string_literal: true

RSpec.describe RailsMFA do
  it "has a version number" do
    expect(RailsMFA::VERSION).not_to be_nil
    expect(RailsMFA::VERSION).to match(/^\d+\.\d+\.\d+/)
  end

  describe ".configure" do
    it "yields a configuration object" do
      expect { |b| RailsMFA.configure(&b) }.to yield_with_args(RailsMFA::Configuration)
    end

    it "stores the configuration" do
      RailsMFA.configure do |c|
        c.code_length = 8
      end

      expect(RailsMFA.configuration.code_length).to eq(8)
    end

    it "allows configuration with provider lambdas" do
      RailsMFA.configure do |c|
        c.sms_provider = ->(to, message) { "sms:#{to}:#{message}" }
        c.email_provider = ->(to, subject, _body) { "email:#{to}:#{subject}" }
      end

      expect(RailsMFA.configuration.sms_provider.call("123", "hi")).to include("sms:123")
      expect(RailsMFA.configuration.email_provider.call("a@b", "s", "b")).to include("email:a@b")
    end

    it "creates a configuration if none exists" do
      RailsMFA.configuration = nil
      RailsMFA.configure {}

      expect(RailsMFA.configuration).to be_a(RailsMFA::Configuration)
    end
  end

  describe "RailsMFA::Error" do
    it "is a StandardError subclass" do
      expect(RailsMFA::Error.new).to be_a(StandardError)
    end
  end
end

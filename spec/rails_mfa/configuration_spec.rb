# frozen_string_literal: true

RSpec.describe RailsMFA::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.sms_provider).to be_nil
      expect(config.email_provider).to be_nil
      expect(config.code_expiry_seconds).to eq(300)
      expect(config.code_length).to eq(6)
    end

    it "sets up a token store" do
      expect(config.token_store).to be_a(RailsMFA::SimpleStore)
    end
  end

  describe "attribute accessors" do
    it "allows setting sms_provider" do
      provider = ->(to, _msg) { "sent to #{to}" }
      config.sms_provider = provider
      expect(config.sms_provider).to eq(provider)
    end

    it "allows setting email_provider" do
      provider = ->(to, _subject, _body) { "emailed #{to}" }
      config.email_provider = provider
      expect(config.email_provider).to eq(provider)
    end

    it "allows setting code_expiry_seconds" do
      config.code_expiry_seconds = 600
      expect(config.code_expiry_seconds).to eq(600)
    end

    it "allows setting code_length" do
      config.code_length = 8
      expect(config.code_length).to eq(8)
    end

    it "allows setting custom token_store" do
      custom_store = double("CustomStore")
      config.token_store = custom_store
      expect(config.token_store).to eq(custom_store)
    end
  end
end

RSpec.describe RailsMFA::SimpleStore do
  let(:store) { described_class.new }
  let(:key) { "test_key" }
  let(:value) { "test_value" }

  describe "#write and #read" do
    it "stores and retrieves values" do
      store.write(key, value)
      expect(store.read(key)).to eq(value)
    end

    it "returns nil for non-existent keys" do
      expect(store.read("nonexistent")).to be_nil
    end

    it "respects expiration time" do
      store.write(key, value, expires_in: 1)
      expect(store.read(key)).to eq(value)

      sleep(2)
      expect(store.read(key)).to be_nil
    end

    it "handles values without expiration" do
      store.write(key, value)
      sleep(1)
      expect(store.read(key)).to eq(value)
    end
  end

  describe "#delete" do
    it "removes a key from storage" do
      store.write(key, value)
      expect(store.read(key)).to eq(value)

      store.delete(key)
      expect(store.read(key)).to be_nil
    end

    it "handles deleting non-existent keys" do
      expect { store.delete("nonexistent") }.not_to raise_error
    end
  end
end

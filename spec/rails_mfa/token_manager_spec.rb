# frozen_string_literal: true

RSpec.describe RailsMFA::TokenManager do
  let(:store) { RailsMFA::SimpleStore.new }
  let(:token_manager) { described_class.new(store: store) }
  let(:user_id) { 123 }

  describe "#generate_numeric_code" do
    it "generates a numeric code of default length" do
      code = token_manager.generate_numeric_code(user_id)
      expect(code).to be_a(String)
      expect(code.length).to eq(RailsMFA.configuration.code_length)
      expect(code).to match(/^\d+$/)
    end

    it "generates a code of specified length" do
      code = token_manager.generate_numeric_code(user_id, length: 4)
      expect(code.length).to eq(4)
      expect(code.to_i).to be >= 1000
      expect(code.to_i).to be < 10000
    end

    it "stores the code in the cache with proper key" do
      code = token_manager.generate_numeric_code(user_id)
      stored_code = store.read("rails_mfa:otp:#{user_id}")
      expect(stored_code).to eq(code)
    end

    it "sets expiration on the stored code" do
      code = token_manager.generate_numeric_code(user_id, expiry: 1)
      expect(store.read("rails_mfa:otp:#{user_id}")).to eq(code)

      sleep(2)
      expect(store.read("rails_mfa:otp:#{user_id}")).to be_nil
    end

    it "generates different codes for different users" do
      code1 = token_manager.generate_numeric_code(user_id)
      code2 = token_manager.generate_numeric_code(456)

      expect(code1).not_to eq(code2)
    end
  end

  describe "#verify_numeric_code" do
    it "verifies a valid code" do
      code = token_manager.generate_numeric_code(user_id)
      expect(token_manager.verify_numeric_code(user_id, code)).to be true
    end

    it "rejects an invalid code" do
      token_manager.generate_numeric_code(user_id)
      expect(token_manager.verify_numeric_code(user_id, "999999")).to be false
    end

    it "rejects code for wrong user" do
      code = token_manager.generate_numeric_code(user_id)
      expect(token_manager.verify_numeric_code(999, code)).to be false
    end

    it "deletes the code after successful verification (one-time use)" do
      code = token_manager.generate_numeric_code(user_id)
      expect(token_manager.verify_numeric_code(user_id, code)).to be true
      expect(token_manager.verify_numeric_code(user_id, code)).to be false
    end

    it "does not delete the code after failed verification" do
      code = token_manager.generate_numeric_code(user_id)
      expect(token_manager.verify_numeric_code(user_id, "wrong")).to be false
      expect(token_manager.verify_numeric_code(user_id, code)).to be true
    end

    it "returns false for expired code" do
      code = token_manager.generate_numeric_code(user_id, expiry: 1)
      sleep(2)
      expect(token_manager.verify_numeric_code(user_id, code)).to be false
    end

    it "uses secure comparison to prevent timing attacks" do
      code = token_manager.generate_numeric_code(user_id)
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original

      token_manager.verify_numeric_code(user_id, code)
      expect(ActiveSupport::SecurityUtils).to have_received(:secure_compare)
    end
  end
end

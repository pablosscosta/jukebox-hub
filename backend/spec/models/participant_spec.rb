require "rails_helper"

RSpec.describe Participant do
  describe "validations" do
    it "requires a name of up to 40 characters" do
      expect(build(:participant, display_name: "")).not_to be_valid
      expect(build(:participant, display_name: "a" * 41)).not_to be_valid
      expect(build(:participant, display_name: "a" * 40)).to be_valid
    end

    it "rejects a long name in the database too" do
      participant = build(:participant, display_name: "a" * 41)

      expect { participant.save!(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /participants_display_name_length_check/)
    end
  end

  describe ".authenticate" do
    it "finds the participant by the raw token, storing only its digest" do
      raw = described_class.generate_token
      participant = create(:participant, token_digest: described_class.digest(raw))

      expect(described_class.authenticate(raw)).to eq(participant)
      expect(described_class.where(token_digest: raw)).to be_empty
    end

    it "returns nil for a blank or unknown token" do
      expect(described_class.authenticate(nil)).to be_nil
      expect(described_class.authenticate("made-up")).to be_nil
    end
  end
end

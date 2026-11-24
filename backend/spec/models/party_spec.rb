require "rails_helper"

RSpec.describe Party do
  let(:host) { create(:host) }

  it "uses a UUID as id, so invite links can't be guessed" do
    party = create(:party)

    expect(party.id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "starts active and expires after the default lifetime" do
    freeze_time do
      party = create(:party)

      expect(party).to be_active
      expect(party.expires_at).to eq(6.hours.from_now)
    end
  end

  describe "validations" do
    it "requires a name of up to 60 characters" do
      expect(build(:party, name: "")).not_to be_valid
      expect(build(:party, name: "a" * 61)).not_to be_valid
      expect(build(:party, name: "a" * 60)).to be_valid
    end

    it "requires a device" do
      expect(build(:party, device_id: nil)).not_to be_valid
    end

    it "rejects an unknown status" do
      expect(build(:party, status: "paused")).not_to be_valid
    end
  end

  describe "one active party per host" do
    it "doesn't allow a second active party" do
      create(:party, host:)

      party = build(:party, host:)

      expect(party).not_to be_valid
      expect(party.errors[:host_id]).to include("already has an active party")
    end

    it "allows a new party once the previous one ended" do
      create(:party, :ended, host:)

      expect(build(:party, host:)).to be_valid
    end

    it "lets different hosts have active parties at the same time" do
      create(:party, host:)

      expect(build(:party)).to be_valid
    end

    it "is also guaranteed by the database" do
      create(:party, host:)
      duplicate = build(:party, host:)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "database constraints" do
    it "rejects an empty name even when validations are skipped" do
      party = build(:party, name: "")

      expect { party.save!(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /parties_name_length_check/)
    end
  end

  describe "#expired?" do
    it "is true once expires_at has passed" do
      expect(build(:party, :expired)).to be_expired
      expect(build(:party)).not_to be_expired
    end
  end
end

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

  describe "#host_participant" do
    it "creates the host's participant once, named after the host" do
      party = create(:party, host: create(:host, display_name: "Pablo"))

      first = party.host_participant

      expect(first).to have_attributes(role: "host", display_name: "Pablo", token_digest: nil)
      expect(party.host_participant).to eq(first)
      expect(party.participants.host.count).to eq(1)
    end

    it "allows only one host participant per party in the database" do
      party = create(:party)
      party.host_participant

      expect { create(:participant, :host, party:) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#expired?" do
    it "is true once expires_at has passed" do
      expect(build(:party, :expired)).to be_expired
      expect(build(:party)).not_to be_expired
    end
  end

  describe "lifetime" do
    it "moves the expiration forward with each activity" do
      party = create(:party)

      travel(2.hours) do
        party.extend_lifetime!

        expect(party.expires_at).to be_within(1.second).of(6.hours.from_now)
      end
    end

    it "records when the party ended" do
      party = create(:party)

      freeze_time do
        party.ended!

        expect(party.ended_at).to eq(Time.current)
      end
    end

    it "knows which parties are overdue and which ended long ago" do
      overdue = create(:party, :expired)
      create(:party)
      old = create(:party, :ended)
      old.update!(ended_at: 25.hours.ago)
      create(:party, :ended)

      expect([described_class.overdue, described_class.ended_long_ago]).to eq([[overdue], [old]])
    end
  end
end

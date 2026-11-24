require "rails_helper"

RSpec.describe Participants::Join do
  let(:party) { create(:party) }

  it "adds the guest to the party and returns a token that identifies them" do
    result = described_class.call(party:, display_name: "  Ana  ")

    expect(result.participant).to have_attributes(party:, display_name: "Ana")
    expect(Participant.authenticate(result.token)).to eq(result.participant)
  end

  it "names a guest without a name after their arrival order" do
    create(:participant, party:)

    result = described_class.call(party:, display_name: " ")

    expect(result.participant.display_name).to eq("Convidado 2")
  end

  it "doesn't let anyone join an ended party" do
    party.ended!

    expect { described_class.call(party:, display_name: "Ana") }.to raise_error(described_class::PartyClosed)
  end

  it "doesn't let anyone join an expired party" do
    party = create(:party, :expired)

    expect { described_class.call(party:, display_name: "Ana") }.to raise_error(described_class::PartyClosed)
  end

  it "rejects a name that is too long" do
    expect { described_class.call(party:, display_name: "a" * 41) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

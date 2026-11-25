require "rails_helper"

RSpec.describe DeleteEndedPartiesJob do
  it "deletes parties that ended more than a day ago, with their guests and queue" do
    old = create(:party, :ended)
    create(:queue_item, participant: create(:participant, party: old))
    old.update!(ended_at: 25.hours.ago)
    recent = create(:party, :ended)

    described_class.perform_now

    expect(Party.where(id: [old.id, recent.id]).pluck(:id)).to eq([recent.id])
    expect(QueueItem.where(party_id: old.id)).to be_empty
  end
end

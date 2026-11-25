require "rails_helper"

RSpec.describe Playback::Stop do
  let(:party) { create(:party) }
  let!(:current) { create(:queue_item, :playing, participant: create(:participant, party:)) }

  it "counts the song as played and pauses the jukebox" do
    described_class.call(party:, expected_current_id: current.id)

    expect(current.reload).to be_played
    expect(party.reload).to be_playback_paused
  end

  it "does nothing when the queue already moved" do
    described_class.call(party:, expected_current_id: current.id + 1)

    expect(current.reload).to be_playing
    expect(party.reload).not_to be_playback_paused
  end
end

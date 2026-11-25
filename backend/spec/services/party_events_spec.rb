require "rails_helper"

RSpec.describe PartyEvents do
  let(:party) { create(:party) }
  let(:participant) { create(:participant, party:) }

  it "sends the notice through Postgres" do
    expect { described_class.publish(party.id, "queue_changed") }.not_to raise_error
  end

  describe "what triggers a notice" do
    before { allow(described_class).to receive(:publish) }

    it "tells the screens when the queue changes" do
      item = create(:queue_item, participant:)
      item.played!

      expect(described_class).to have_received(:publish).with(party.id, "queue_changed").twice
    end

    it "tells the screens when the party ends" do
      party.ended!

      expect(described_class).to have_received(:publish).with(party.id, "party_ended")
    end

    it "tells the screens when the host's own Spotify song starts" do
      party.update!(external_track: { trackId: "hostChoice000000000000" })

      expect(described_class).to have_received(:publish).with(party.id, "queue_changed")
    end

    it "stays quiet for changes the screens don't show" do
      party.update!(playback_checked_at: Time.current)

      expect(described_class).not_to have_received(:publish)
    end
  end
end

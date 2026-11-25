require "rails_helper"

RSpec.describe QueueItem do
  let(:party) { create(:party) }
  let(:participant) { create(:participant, party:) }

  it "starts pending" do
    expect(create(:queue_item, participant:)).to be_pending
  end

  it "requires a positive duration" do
    expect(build(:queue_item, participant:, duration_ms: 0)).not_to be_valid
  end

  describe "database constraints" do
    it "doesn't allow the same song twice while it is waiting or playing" do
      create(:queue_item, participant:, track_id: SpotifyHelpers::TRACK_ID)

      expect { create(:queue_item, participant:, track_id: SpotifyHelpers::TRACK_ID) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "lets a song come back once it was played" do
      create(:queue_item, :played, participant:, track_id: SpotifyHelpers::TRACK_ID)

      expect(create(:queue_item, participant:, track_id: SpotifyHelpers::TRACK_ID)).to be_persisted
    end

    it "allows only one song playing per party" do
      create(:queue_item, :playing, participant:)

      expect { create(:queue_item, :playing, participant:) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects an unknown status even when validations are skipped" do
      item = build(:queue_item, participant:)
      item.status = "paused"

      expect { item.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /queue_items_status_check/)
    end
  end
end

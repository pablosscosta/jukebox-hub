require "rails_helper"

RSpec.describe CheckPlaybackJob do
  let(:party) { create(:party) }
  let!(:current) { create(:queue_item, :playing, participant: create(:participant, party:)) }
  let(:watch_key) { "item:#{current.id}" }

  before { stub_spotify_play }

  def check(key = watch_key, ending: false)
    described_class.perform_now(party.id, key, ending)
  end

  it "checks again a few seconds before the end while the song is still playing" do
    stub_spotify_playback(track_id: current.track_id, progress_ms: 60_000, duration_ms: 180_000)

    freeze_time do
      check

      expect(described_class).to have_been_enqueued.with(party.id, watch_key, false).at(115.seconds.from_now)
    end
  end

  it "checks right after the end when the song is about to finish" do
    stub_spotify_playback(track_id: current.track_id, progress_ms: 177_000, duration_ms: 180_000)

    freeze_time do
      check

      expect(described_class).to have_been_enqueued.with(party.id, watch_key, true).at(4.seconds.from_now)
    end
  end

  it "waits while the host has the song paused" do
    stub_spotify_playback(track_id: current.track_id, playing: false, progress_ms: 60_000)

    freeze_time do
      check

      expect(described_class).to have_been_enqueued.with(party.id, watch_key, false).at(30.seconds.from_now)
    end
  end

  it "moves the queue when the song finished" do
    stub_spotify_playback(track_id: current.track_id, playing: false, progress_ms: 0)

    check

    expect(current.reload).to be_played
  end

  it "does nothing when the party already moved on (e.g. the host skipped)" do
    current.played!

    check

    expect(a_request(:get, SpotifyHelpers::PLAYER_URL)).not_to have_been_made
  end

  it "does nothing once the party is over" do
    party.ended!

    check

    expect(a_request(:get, SpotifyHelpers::PLAYER_URL)).not_to have_been_made
  end
end

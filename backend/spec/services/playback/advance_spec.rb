require "rails_helper"

RSpec.describe Playback::Advance do
  let(:party) { create(:party) }
  let(:ana) { create(:participant, party:) }
  let(:bruno) { create(:participant, party:) }
  let(:spotify) { Spotify::ApiClient.new(access_token: "host-access-token") }

  before { stub_spotify_play }

  def advance(expected_current_id)
    described_class.call(party:, spotify:, expected_current_id:)
  end

  it "starts the first song in the fair order on the party's device" do
    first = create(:queue_item, participant: ana)
    create(:queue_item, participant: bruno)

    expect(advance(nil).status).to eq(:playing)
    expect(first.reload).to be_playing
    expect(a_request(:put, SpotifyHelpers::PLAY_URL)
      .with(query: { "device_id" => party.device_id },
            body: hash_including("uris" => ["spotify:track:#{first.track_id}"]))).to have_been_made
  end

  it "schedules a check a few seconds before the song ends" do
    first = create(:queue_item, participant: ana, duration_ms: 180_000)

    freeze_time do
      advance(nil)

      expect(first.reload.started_at).to eq(Time.current)
      expect(CheckPlaybackJob).to have_been_enqueued.with(party.id, "item:#{first.id}", false).at(175.seconds.from_now)
    end
  end

  it "marks the current song as played and plays the next one" do
    current = create(:queue_item, :playing, participant: ana)
    next_song = create(:queue_item, participant: bruno)

    advance(current.id)

    expect(current.reload).to be_played
    expect(next_song.reload).to be_playing
  end

  it "does nothing when the queue already moved" do
    current = create(:queue_item, :playing, participant: ana)
    create(:queue_item, participant: bruno)

    result = advance(current.id - 1)

    expect(result.status).to eq(:stale)
    expect(current.reload).to be_playing
    expect(a_request(:put, SpotifyHelpers::PLAY_URL).with(query: hash_including({}))).not_to have_been_made
  end

  it "doesn't start a second song when one is already playing" do
    create(:queue_item, :playing, participant: ana)

    expect(advance(nil).status).to eq(:stale)
  end

  it "stops when there is nothing left to play" do
    current = create(:queue_item, :playing, participant: ana)

    expect(advance(current.id).status).to eq(:idle)
    expect(current.reload).to be_played
  end

  it "keeps the next song waiting when Spotify isn't open on the device" do
    stub_spotify_play(status: 404)
    current = create(:queue_item, :playing, participant: ana)
    next_song = create(:queue_item, participant: bruno)

    expect(advance(current.id).status).to eq(:device_unavailable)
    expect(next_song.reload).to be_pending
    expect(CheckPlaybackJob).not_to have_been_enqueued
  end

  it "turns the jukebox back on after the host paused it" do
    party.update!(playback_paused: true)
    create(:queue_item, participant: ana)

    advance(nil)

    expect(party.reload).not_to be_playback_paused
  end
end

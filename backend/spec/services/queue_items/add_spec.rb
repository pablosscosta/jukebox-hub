require "rails_helper"

RSpec.describe QueueItems::Add do
  let(:party) { create(:party) }
  let(:participant) { create(:participant, party:) }
  let(:spotify) { Spotify::ApiClient.new(access_token: "host-access-token") }

  def add(track_id = SpotifyHelpers::TRACK_ID, by: participant)
    described_class.call(participant: by, track_id:, spotify:)
  end

  it "adds the song with the details Spotify gives" do
    stub_spotify_track

    item = add

    expect(item).to have_attributes(party:, participant:, status: "pending", track_id: SpotifyHelpers::TRACK_ID,
                                    title: "Garota de Ipanema", artist: "Tom Jobim", duration_ms: 323_000,
                                    image_url: "https://i.scdn.co/image/300")
  end

  it "rejects an id that isn't a Spotify id, without calling Spotify" do
    expect { add("../me/player") }.to raise_error(described_class::InvalidTrack)
    expect(a_request(:get, /api.spotify.com/)).not_to have_been_made
  end

  it "rejects a song Spotify doesn't know" do
    stub_spotify_track(nil, status: 404)

    expect { add }.to raise_error(described_class::InvalidTrack)
  end

  it "rejects a song that is already in the queue, even if someone else added it" do
    stub_spotify_track
    create(:queue_item, participant: create(:participant, party:), track_id: SpotifyHelpers::TRACK_ID)

    expect { add }.to raise_error(described_class::AlreadyQueued)
  end

  it "accepts a song again once it was played" do
    stub_spotify_track
    create(:queue_item, :played, participant:, track_id: SpotifyHelpers::TRACK_ID)

    expect(add).to be_persisted
  end

  describe "limit of pending songs" do
    before { stub_spotify_track }

    it "doesn't let a participant have more than 5 songs waiting" do
      create_list(:queue_item, 5, participant:)

      expect { add }.to raise_error(described_class::LimitReached)
    end

    it "doesn't count songs that already played" do
      create_list(:queue_item, 4, participant:)
      create(:queue_item, :played, participant:)

      expect(add).to be_persisted
    end

    it "counts each participant separately" do
      create_list(:queue_item, 5, participant: create(:participant, party:))

      expect(add).to be_persisted
    end

    it "applies to the host too" do
      host = party.host_participant
      create_list(:queue_item, 5, participant: host)

      expect { add(by: host) }.to raise_error(described_class::LimitReached)
    end
  end
end

require "rails_helper"

RSpec.describe Spotify::ApiClient do
  subject(:client) { described_class.new(access_token: "host-access-token") }

  describe "#me" do
    it "returns the profile, authenticated as the host" do
      stub_spotify_me

      expect(client.me).to include("id" => "spotify-user-1", "display_name" => "Pablo")
      expect(a_request(:get, SpotifyHelpers::ME_URL)
        .with(headers: { "Authorization" => "Bearer host-access-token" })).to have_been_made
    end
  end

  describe "#devices" do
    it "turns the Spotify response into devices" do
      stub_spotify_devices([spotify_device, spotify_device(id: "device-2", name: "Celular", type: "Smartphone",
                                                           is_active: false)])

      notebook = Spotify::Device.new(id: "device-1", name: "Notebook", type: "Computer", active: true,
                                     restricted: false)
      phone = Spotify::Device.new(id: "device-2", name: "Celular", type: "Smartphone", active: false,
                                  restricted: false)
      expect(client.devices).to eq([notebook, phone])
    end

    it "returns an empty list when Spotify isn't open anywhere" do
      stub_spotify_devices([])

      expect(client.devices).to eq([])
    end

    it "raises Spotify::Error when Spotify fails" do
      stub_spotify_devices([], status: 503)

      expect { client.devices }.to raise_error(Spotify::Error) { |error| expect(error.status).to eq(503) }
    end
  end

  describe "#search_tracks" do
    it "searches tracks playable in the host's country, up to 10" do
      stub_spotify_search

      tracks = client.search_tracks("ipanema")

      expect(tracks.map(&:title)).to eq(["Garota de Ipanema"])
      expect(a_request(:get, SpotifyHelpers::SEARCH_URL)
        .with(query: { "type" => "track", "q" => "ipanema", "limit" => "10", "market" => "from_token" },
              headers: { "Authorization" => "Bearer host-access-token" })).to have_been_made
    end

    it "leaves out tracks that can't be played" do
      stub_spotify_search([spotify_track(id: "blocked", is_playable: false), nil, spotify_track])

      expect(client.search_tracks("ipanema").map(&:id)).to eq([SpotifyHelpers::TRACK_ID])
    end

    it "returns an empty list when nothing matches" do
      stub_spotify_search([])

      expect(client.search_tracks("zzzz")).to eq([])
    end

    it "raises Spotify::Error when Spotify fails" do
      stub_spotify_search([], status: 429)

      expect { client.search_tracks("ipanema") }.to raise_error(Spotify::Error)
    end
  end

  describe "#track" do
    it "returns the track, as playable in the host's country" do
      stub_spotify_track

      expect(client.track(SpotifyHelpers::TRACK_ID)).to have_attributes(id: SpotifyHelpers::TRACK_ID,
                                                                        title: "Garota de Ipanema")
      expect(a_request(:get, "#{SpotifyHelpers::TRACKS_URL}/#{SpotifyHelpers::TRACK_ID}")
        .with(query: { "market" => "from_token" })).to have_been_made
    end

    it "returns nil when the track doesn't exist" do
      stub_spotify_track(nil, status: 404)

      expect(client.track(SpotifyHelpers::TRACK_ID)).to be_nil
    end

    it "returns nil when the track can't be played in the host's country" do
      stub_spotify_track(spotify_track(is_playable: false))

      expect(client.track(SpotifyHelpers::TRACK_ID)).to be_nil
    end

    it "raises Spotify::Error for other failures" do
      stub_spotify_track(nil, status: 500)

      expect { client.track(SpotifyHelpers::TRACK_ID) }.to raise_error(Spotify::Error)
    end
  end

  describe "#play" do
    it "starts the track on the given device" do
      stub_spotify_play

      client.play(device_id: "device-1", track_id: SpotifyHelpers::TRACK_ID)

      expect(a_request(:put, SpotifyHelpers::PLAY_URL)
        .with(query: { "device_id" => "device-1" }, body: { uris: ["spotify:track:#{SpotifyHelpers::TRACK_ID}"] }))
        .to have_been_made
    end

    it "raises DeviceNotFoundError when the device is gone" do
      stub_spotify_play(status: 404)

      expect { client.play(device_id: "device-1", track_id: SpotifyHelpers::TRACK_ID) }
        .to raise_error(Spotify::DeviceNotFoundError)
    end

    it "raises Spotify::Error for other failures" do
      stub_spotify_play(status: 403)

      expect { client.play(device_id: "device-1", track_id: SpotifyHelpers::TRACK_ID) }
        .to raise_error(Spotify::Error) { |error| expect(error).not_to be_a(Spotify::DeviceNotFoundError) }
    end
  end

  describe "#playback" do
    it "says what is playing and how far it went" do
      stub_spotify_playback(track_id: "abc", progress_ms: 60_000, duration_ms: 180_000)

      expect(client.playback).to have_attributes(track_id: "abc", playing: true, remaining_ms: 120_000)
    end

    it "is nil when Spotify isn't playing anywhere" do
      stub_spotify_playback

      expect(client.playback).to be_nil
    end
  end

  describe "#pause" do
    it "pauses the music on the given device" do
      stub_spotify_pause

      client.pause(device_id: "device-1")

      expect(a_request(:put, SpotifyHelpers::PAUSE_URL).with(query: { "device_id" => "device-1" })).to have_been_made
    end
  end
end

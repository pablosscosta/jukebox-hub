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
end

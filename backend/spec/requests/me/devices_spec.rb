require "rails_helper"

RSpec.describe "GET /me/devices" do
  let(:host) { create(:host, access_token: "host-access-token") }
  let(:headers) { { "Authorization" => "Bearer #{HostToken.issue!(host:, kind: :access)}" } }

  it "lists the host's Spotify devices" do
    stub_spotify_devices([spotify_device, spotify_device(id: "device-2", name: "Celular", type: "Smartphone",
                                                         is_active: false)])

    get("/me/devices", headers:)

    expect(response).to have_http_status(:ok)
    notebook = { "id" => "device-1", "name" => "Notebook", "type" => "Computer", "isActive" => true }
    phone = { "id" => "device-2", "name" => "Celular", "type" => "Smartphone", "isActive" => false }
    expect(response.parsed_body).to eq([notebook, phone])
    expect(a_request(:get, SpotifyHelpers::DEVICES_URL)
      .with(headers: { "Authorization" => "Bearer host-access-token" })).to have_been_made
  end

  it "leaves out devices that can't be controlled" do
    stub_spotify_devices([spotify_device(id: "tv", is_restricted: true), spotify_device(id: nil)])

    get("/me/devices", headers:)

    expect(response.parsed_body).to eq([])
  end

  it "renews an expired Spotify token before asking for the devices" do
    host.update!(token_expires_at: 1.minute.ago)
    stub_spotify_token
    stub_spotify_devices

    get("/me/devices", headers:)

    expect(response).to have_http_status(:ok)
    expect(a_request(:get, SpotifyHelpers::DEVICES_URL)
      .with(headers: { "Authorization" => "Bearer new-access-token" })).to have_been_made
  end

  it "answers 401 when the host revoked access on Spotify" do
    host.update!(token_expires_at: 1.minute.ago)
    stub_spotify_token({ "error" => "invalid_grant" }, status: 400)

    get("/me/devices", headers:)

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end

  it "answers 502 when Spotify fails" do
    stub_spotify_devices([], status: 503)

    get("/me/devices", headers:)

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body.dig("error", "code")).to eq("spotify_unavailable")
  end

  it "answers 401 without a token" do
    get "/me/devices"

    expect(response).to have_http_status(:unauthorized)
  end
end

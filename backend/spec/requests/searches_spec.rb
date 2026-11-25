require "rails_helper"

RSpec.describe "GET /parties/:id/search" do
  let(:host) { create(:host, access_token: "host-access-token") }
  let(:party) { create(:party, host:) }
  let(:guest_token) { Participant.generate_token }

  before { create(:participant, party:, token_digest: Participant.digest(guest_token)) }

  def search(query = "ipanema", bearer: guest_token, party_id: party.id)
    get "/parties/#{party_id}/search", params: { q: query }, headers: { "Authorization" => "Bearer #{bearer}" }
  end

  it "lets a guest search songs, using the host's Spotify account" do
    stub_spotify_search

    search

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([{ "trackId" => "track-1", "title" => "Garota de Ipanema",
                                          "artist" => "Tom Jobim", "durationMs" => 323_000,
                                          "imageUrl" => "https://i.scdn.co/image/300" }])
    expect(a_request(:get, SpotifyHelpers::SEARCH_URL).with(query: hash_including("q" => "ipanema"),
                                                            headers: { "Authorization" => "Bearer host-access-token" }))
      .to have_been_made
  end

  it "lets the host search with their own token" do
    stub_spotify_search

    search(bearer: HostToken.issue!(host:, kind: :access))

    expect(response).to have_http_status(:ok)
  end

  it "answers 422 for an empty search, without calling Spotify" do
    search("   ")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_query")
    expect(a_request(:get, SpotifyHelpers::SEARCH_URL).with(query: hash_including({}))).not_to have_been_made
  end

  it "answers 422 for a search longer than 100 characters" do
    search("a" * 101)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "answers 401 without a valid participant token" do
    search(bearer: "unknown")

    expect(response).to have_http_status(:unauthorized)
  end

  it "answers 410 when the party is over" do
    party.ended!

    search

    expect(response).to have_http_status(:gone)
  end

  it "answers 404 for a party that doesn't exist" do
    search(party_id: SecureRandom.uuid)

    expect(response).to have_http_status(:not_found)
  end

  it "answers 503 when the host's Spotify got disconnected, without asking the guest to log in" do
    host.update!(token_expires_at: 1.minute.ago)
    stub_spotify_token({ "error" => "invalid_grant" }, status: 400)

    search

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("host_spotify_disconnected")
  end

  it "answers 502 when Spotify fails" do
    stub_spotify_search([], status: 503)

    search

    expect(response).to have_http_status(:bad_gateway)
    expect(response.parsed_body.dig("error", "code")).to eq("spotify_unavailable")
  end
end

require "rails_helper"

RSpec.describe "Queue" do
  let(:host) { create(:host, access_token: "host-access-token") }
  let(:party) { create(:party, host:) }
  let(:guest_token) { Participant.generate_token }
  let!(:guest) { create(:participant, party:, display_name: "Ana", token_digest: Participant.digest(guest_token)) }
  let(:headers) { { "Authorization" => "Bearer #{guest_token}" } }

  describe "POST /parties/:id/queue" do
    def add_song(track_id = SpotifyHelpers::TRACK_ID, bearer: guest_token)
      post "/parties/#{party.id}/queue", params: { trackId: track_id }, as: :json,
                                         headers: { "Authorization" => "Bearer #{bearer}" }
    end

    it "adds a song to the queue" do
      stub_spotify_track

      add_song

      item = QueueItem.last
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "id" => item.id.to_s, "trackId" => SpotifyHelpers::TRACK_ID, "title" => "Garota de Ipanema",
        "artist" => "Tom Jobim", "durationMs" => 323_000, "imageUrl" => "https://i.scdn.co/image/300",
        "status" => "pending", "addedBy" => { "id" => guest.id.to_s, "displayName" => "Ana" },
        "addedAt" => item.created_at.as_json
      )
      expect(a_request(:get, %r{/v1/tracks/}).with(headers: { "Authorization" => "Bearer host-access-token" }))
        .to have_been_made
    end

    it "lets the host add songs as a participant" do
      stub_spotify_track

      add_song(bearer: HostToken.issue!(host:, kind: :access))

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("addedBy", "id")).to eq(party.host_participant.id.to_s)
    end

    it "answers 409 for a song that is already in the queue" do
      stub_spotify_track
      create(:queue_item, participant: guest, track_id: SpotifyHelpers::TRACK_ID)

      add_song

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("already_queued")
    end

    it "answers 409 when the participant already has 5 songs waiting" do
      stub_spotify_track
      create_list(:queue_item, 5, participant: guest)

      add_song

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("queue_limit_reached")
    end

    it "answers 422 for a song Spotify doesn't know" do
      add_song("not-a-spotify-id")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_track")
    end

    it "answers 401 without a participant token" do
      add_song(bearer: "unknown")

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 410 when the party is over" do
      party.ended!

      add_song

      expect(response).to have_http_status(:gone)
    end
  end

  describe "GET /parties/:id/queue" do
    it "shows the song that is playing" do
      playing = create(:queue_item, :playing, participant: guest)

      get("/parties/#{party.id}/queue", headers:)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["nowPlaying"]).to include("id" => playing.id.to_s, "status" => "playing")
    end

    it "lists what comes next in play order" do
      create(:queue_item, :playing, participant: guest)
      ana_next, ana_later = create_list(:queue_item, 2, participant: guest)
      bruno_song = create(:queue_item, participant: create(:participant, party:))

      get("/parties/#{party.id}/queue", headers:)

      # Ana is playing and would be next too, so Bruno's song comes before her third one.
      expect(response.parsed_body["upNext"].pluck("id")).to eq([ana_next, bruno_song, ana_later].map { |i| i.id.to_s })
    end

    it "returns an empty queue" do
      get("/parties/#{party.id}/queue", headers:)

      expect(response.parsed_body).to eq("nowPlaying" => nil, "upNext" => [], "maxPendingPerParticipant" => 5)
    end

    it "leaves out songs that already played or were removed" do
      create(:queue_item, :played, participant: guest)
      create(:queue_item, participant: guest, status: :removed)

      get("/parties/#{party.id}/queue", headers:)

      expect(response.parsed_body["upNext"]).to eq([])
    end

    it "answers 401 without a participant token" do
      get "/parties/#{party.id}/queue"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

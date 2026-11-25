require "rails_helper"

RSpec.describe "Queue" do
  let(:host) { create(:host, access_token: "host-access-token") }
  let(:party) { create(:party, host:) }
  let(:guest_token) { Participant.generate_token }
  let!(:guest) { create(:participant, party:, display_name: "Ana", token_digest: Participant.digest(guest_token)) }
  let(:headers) { { "Authorization" => "Bearer #{guest_token}" } }

  describe "POST /parties/:id/queue" do
    before { stub_spotify_play }

    def add_song(track_id = SpotifyHelpers::TRACK_ID, bearer: guest_token)
      post "/parties/#{party.id}/queue", params: { trackId: track_id }, as: :json,
                                         headers: { "Authorization" => "Bearer #{bearer}" }
    end

    it "adds a song to the queue, starting it when nothing was playing" do
      stub_spotify_track

      add_song

      item = QueueItem.last
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(
        "id" => item.id.to_s, "trackId" => SpotifyHelpers::TRACK_ID, "title" => "Garota de Ipanema",
        "artist" => "Tom Jobim", "durationMs" => 323_000, "imageUrl" => "https://i.scdn.co/image/300",
        "status" => "playing", "addedBy" => { "id" => guest.id.to_s, "displayName" => "Ana" },
        "addedAt" => item.created_at.as_json, "startedAt" => item.started_at.as_json
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
    before { stub_spotify_playback(track_id: SpotifyHelpers::TRACK_ID) }

    it "shows the song that is playing" do
      playing = create(:queue_item, :playing, participant: guest, track_id: SpotifyHelpers::TRACK_ID)

      get("/parties/#{party.id}/queue", headers:)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["nowPlaying"]).to include("id" => playing.id.to_s, "status" => "playing")
    end

    it "lists what comes next in play order" do
      create(:queue_item, :playing, participant: guest, track_id: SpotifyHelpers::TRACK_ID)
      ana_next, ana_later = create_list(:queue_item, 2, participant: guest)
      bruno_song = create(:queue_item, participant: create(:participant, party:))

      get("/parties/#{party.id}/queue", headers:)

      # Ana is playing and would be next too, so Bruno's song comes before her third one.
      expect(response.parsed_body["upNext"].pluck("id")).to eq([ana_next, bruno_song, ana_later].map { |i| i.id.to_s })
    end

    it "returns an empty queue" do
      get("/parties/#{party.id}/queue", headers:)

      expect(response.parsed_body).to eq("nowPlaying" => nil, "upNext" => [], "maxPendingPerParticipant" => 5,
                                         "playbackState" => "idle", "externalTrack" => nil)
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

  describe "DELETE /parties/:id/queue/:item_id" do
    def remove(item, bearer: HostToken.issue!(host:, kind: :access))
      delete "/parties/#{party.id}/queue/#{item.id}", headers: { "Authorization" => "Bearer #{bearer}" }
    end

    it "lets the host take a song out of the queue" do
      item = create(:queue_item, participant: guest)

      remove(item)

      expect(response).to have_http_status(:no_content)
      expect(item.reload).to be_removed
    end

    it "answers 404 for a song that is not waiting anymore" do
      item = create(:queue_item, :playing, participant: guest)

      remove(item)

      expect(response).to have_http_status(:not_found)
      expect(item.reload).to be_playing
    end

    it "answers 403 to a guest, even for their own song" do
      item = create(:queue_item, participant: guest)

      remove(item, bearer: guest_token)

      expect(response).to have_http_status(:forbidden)
      expect(item.reload).to be_pending
    end
  end

  describe "checking Spotify when the queue is opened" do
    def open_queue
      get("/parties/#{party.id}/queue", headers:)
    end

    it "shows the song the host played straight from Spotify" do
      playing = create(:queue_item, :playing, participant: guest)
      stub_spotify_playback(track_id: "hostChoice000000000000", progress_ms: 5_000)

      open_queue

      body = response.parsed_body
      expect(body).to include("nowPlaying" => nil, "playbackState" => "external")
      expect(body["externalTrack"]).to include("trackId" => "hostChoice000000000000")
      expect(playing.reload).to be_played
    end

    it "asks Spotify at most once every 20 seconds per party" do
      playing = create(:queue_item, :playing, participant: guest)
      stub_spotify_playback(track_id: playing.track_id, progress_ms: 5_000)

      2.times { open_queue }
      travel(21.seconds) { open_queue }

      expect(a_request(:get, SpotifyHelpers::PLAYER_URL)).to have_been_made.twice
    end

    it "still shows the queue when Spotify fails" do
      playing = create(:queue_item, :playing, participant: guest)
      stub_request(:get, SpotifyHelpers::PLAYER_URL).to_return(status: 503)

      open_queue

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("nowPlaying", "id")).to eq(playing.id.to_s)
    end
  end
end

require "rails_helper"

RSpec.describe "Playback" do
  let(:host) { create(:host, access_token: "host-access-token") }
  let(:party) { create(:party, host:) }
  let(:host_token) { HostToken.issue!(host:, kind: :access) }
  let(:ana) { create(:participant, party:) }

  before { stub_spotify_play }

  def post_as(path, bearer: host_token)
    post "/parties/#{party.id}/playback/#{path}", headers: { "Authorization" => "Bearer #{bearer}" }
  end

  describe "POST /parties/:id/playback/next" do
    it "lets the host skip the song that is playing" do
      current = create(:queue_item, :playing, participant: ana)
      next_song = create(:queue_item, participant: ana)

      post_as("next")

      expect(response).to have_http_status(:no_content)
      expect(current.reload).to be_played
      expect(next_song.reload).to be_playing
    end

    it "answers 403 to a guest" do
      guest_token = Participant.generate_token
      create(:participant, party:, token_digest: Participant.digest(guest_token))

      post_as("next", bearer: guest_token)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
    end
  end

  describe "POST /parties/:id/playback/start" do
    it "starts the queue after the host paused the jukebox" do
      party.update!(playback_paused: true)
      song = create(:queue_item, participant: ana)

      post_as("start")

      expect(response).to have_http_status(:no_content)
      expect(song.reload).to be_playing
      expect(party.reload).not_to be_playback_paused
    end

    it "doesn't skip the song that is already playing" do
      current = create(:queue_item, :playing, participant: ana)
      create(:queue_item, participant: ana)

      post_as("start")

      expect(response).to have_http_status(:no_content)
      expect(current.reload).to be_playing
    end

    it "answers 422 when Spotify isn't open on the party's device" do
      stub_spotify_play(status: 404)
      create(:queue_item, participant: ana)

      post_as("start")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("device_unavailable")
    end
  end
end

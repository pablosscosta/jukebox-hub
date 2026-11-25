require "rails_helper"

RSpec.describe "Participants" do
  let(:party) { create(:party) }

  describe "POST /parties/:id/participants" do
    it "lets a guest join without login and returns their token" do
      freeze_time do
        post "/parties/#{party.id}/participants", params: { displayName: "Ana" }, as: :json

        participant = Participant.last
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "participantToken" => response.parsed_body["participantToken"],
          "participant" => { "id" => participant.id.to_s, "displayName" => "Ana", "role" => "guest",
                             "joinedAt" => Time.current.as_json }
        )
        expect(Participant.authenticate(response.parsed_body["participantToken"])).to eq(participant)
      end
    end

    it "accepts a guest without a name" do
      post "/parties/#{party.id}/participants", as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("participant", "displayName")).to eq("Convidado 1")
    end

    it "answers 410 when the party is over" do
      party.ended!

      post "/parties/#{party.id}/participants", params: { displayName: "Ana" }, as: :json

      expect(response).to have_http_status(:gone)
      expect(response.parsed_body.dig("error", "code")).to eq("party_ended")
    end

    it "answers 404 for a link that doesn't exist" do
      post "/parties/#{SecureRandom.uuid}/participants", as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("party_not_found")
    end

    it "answers 422 when the name is too long" do
      post "/parties/#{party.id}/participants", params: { displayName: "a" * 41 }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_participant")
    end
  end

  describe "GET /parties/:id/participants/me" do
    let(:token) { Participant.generate_token }
    let!(:participant) { create(:participant, party:, display_name: "Ana", token_digest: Participant.digest(token)) }

    def get_me(party_id: party.id, bearer: token)
      get "/parties/#{party_id}/participants/me", headers: { "Authorization" => "Bearer #{bearer}" }
    end

    it "returns the guest who owns the token" do
      get_me

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id" => participant.id.to_s, "displayName" => "Ana")
    end

    it "answers 401 with a token from another party" do
      get_me(party_id: create(:party).id)

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 401 with an unknown token" do
      get_me(bearer: "made-up")

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the host's own participant when called with the host's token" do
      host_token = HostToken.issue!(host: party.host, kind: :access)

      get_me(bearer: host_token)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("role" => "host", "displayName" => party.host.display_name)
    end

    it "answers 401 with the token of another party's host" do
      get_me(bearer: HostToken.issue!(host: create(:host), kind: :access))

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 410 once the party is over" do
      party.ended!

      get_me

      expect(response).to have_http_status(:gone)
    end
  end
end

require "rails_helper"

RSpec.describe "Parties" do
  describe "GET /parties/:id" do
    it "shows the public data of the party, without login" do
      party = create(:party, name: "Churrasco", host: create(:host, display_name: "Pablo"))

      get "/parties/#{party.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "id" => party.id, "name" => "Churrasco", "status" => "active", "hostName" => "Pablo",
        "expiresAt" => party.expires_at.as_json
      )
    end

    it "shows an expired party as ended" do
      party = create(:party, :expired)

      get "/parties/#{party.id}"

      expect(response.parsed_body["status"]).to eq("ended")
    end

    it "answers 404 for an unknown or malformed id" do
      get "/parties/#{SecureRandom.uuid}"
      expect(response).to have_http_status(:not_found)

      get "/parties/not-a-uuid"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /parties" do
    let(:host) { create(:host) }
    let(:headers) { { "Authorization" => "Bearer #{HostToken.issue!(host:, kind: :access)}" } }

    def create_party(params = { name: "Churrasco", deviceId: "device-1" })
      post "/parties", params:, headers:, as: :json
    end

    before { stub_spotify_devices([spotify_device(id: "device-1", name: "pablo-note")]) }

    it "creates the party and returns it with the invite link" do
      freeze_time do
        create_party

        party = Party.last
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq(
          "id" => party.id, "name" => "Churrasco", "status" => "active", "deviceName" => "pablo-note",
          "shareUrl" => "http://127.0.0.1:5173/p/#{party.id}",
          "expiresAt" => 6.hours.from_now.as_json, "createdAt" => Time.current.as_json
        )
      end
    end

    it "builds the invite link from INVITE_ORIGIN, so phones on the Wi-Fi can open it" do
      allow(Rails.configuration.x).to receive(:invite_origin).and_return("http://10.0.0.5:5173")

      create_party

      expect(response.parsed_body["shareUrl"]).to eq("http://10.0.0.5:5173/p/#{Party.last.id}")
    end

    it "answers 409 with the current party when the host already has one" do
      current = create(:party, host:)

      create_party

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("active_party_exists")
      expect(response.parsed_body.dig("party", "id")).to eq(current.id)
    end

    it "answers 403 when the host isn't Premium" do
      host.update!(product: "free")

      create_party

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("premium_required")
    end

    it "answers 422 when the device isn't available" do
      create_party(name: "Churrasco", deviceId: "closed-device")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("device_unavailable")
    end

    it "answers 422 when the name is missing" do
      create_party(deviceId: "device-1")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_party")
    end

    it "answers 401 without a token" do
      post "/parties", params: { name: "Churrasco", deviceId: "device-1" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(Party.count).to eq(0)
    end
  end
end

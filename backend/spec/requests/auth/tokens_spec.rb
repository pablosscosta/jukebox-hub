require "rails_helper"

RSpec.describe "Host access token" do
  let(:host) { create(:host, display_name: "Pablo") }

  describe "POST /auth/token" do
    it "trades a login code for an access token" do
      code = HostToken.issue!(host:, kind: :login_code)

      post "/auth/token", params: { code: }, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("host" => { "id" => host.id.to_s, "displayName" => "Pablo" })
      expect(HostToken.find_active(response.parsed_body["token"], kind: :access).host).to eq(host)
    end

    it "doesn't accept the same code twice" do
      code = HostToken.issue!(host:, kind: :login_code)
      post "/auth/token", params: { code: }, as: :json

      post "/auth/token", params: { code: }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_login_code")
    end

    it "doesn't accept an expired code" do
      code = HostToken.issue!(host:, kind: :login_code)

      travel 2.minutes do
        post "/auth/token", params: { code: }, as: :json
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it "doesn't accept an access token as login code" do
      token = HostToken.issue!(host:, kind: :access)

      post "/auth/token", params: { code: token }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "answers 401 when no code is sent" do
      post "/auth/token", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /auth/token" do
    it "logs out: the token stops working" do
      token = HostToken.issue!(host:, kind: :access)
      headers = { "Authorization" => "Bearer #{token}" }

      delete("/auth/token", headers:)
      get("/me", headers:)

      expect(response).to have_http_status(:unauthorized)
    end

    it "requires a token" do
      delete "/auth/token"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

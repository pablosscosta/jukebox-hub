require "rails_helper"

RSpec.describe "GET /me/party" do
  let(:host) { create(:host) }
  let(:headers) { { "Authorization" => "Bearer #{HostToken.issue!(host:, kind: :access)}" } }

  it "returns the host's active party" do
    party = create(:party, host:, name: "Churrasco")

    get("/me/party", headers:)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("id" => party.id, "name" => "Churrasco",
                                            "shareUrl" => "http://127.0.0.1:5173/p/#{party.id}")
  end

  it "answers 404 when there is no active party" do
    create(:party, :ended, host:)

    get("/me/party", headers:)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("no_active_party")
  end

  it "doesn't show another host's party" do
    create(:party)

    get("/me/party", headers:)

    expect(response).to have_http_status(:not_found)
  end

  it "answers 401 without a token" do
    get "/me/party"

    expect(response).to have_http_status(:unauthorized)
  end
end

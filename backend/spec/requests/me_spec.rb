require "rails_helper"

RSpec.describe "GET /me" do
  let(:host) { create(:host, display_name: "Pablo") }

  it "returns the logged-in host" do
    token = HostToken.issue!(host:, kind: :access)

    get "/me", headers: { "Authorization" => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("id" => host.id.to_s, "displayName" => "Pablo")
  end

  it "never exposes the Spotify tokens" do
    token = HostToken.issue!(host:, kind: :access)

    get "/me", headers: { "Authorization" => "Bearer #{token}" }

    expect(response.body).not_to include(host.access_token, host.refresh_token)
  end

  it "answers 401 without a token" do
    get "/me"

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq(
      "error" => { "code" => "unauthorized", "message" => "Faça login com o Spotify para continuar." }
    )
  end

  it "answers 401 with an unknown token" do
    get "/me", headers: { "Authorization" => "Bearer made-up" }

    expect(response).to have_http_status(:unauthorized)
  end

  it "answers 401 with an expired token" do
    token = HostToken.issue!(host:, kind: :access)

    travel 8.days do
      get "/me", headers: { "Authorization" => "Bearer #{token}" }
    end

    expect(response).to have_http_status(:unauthorized)
  end
end

require "rails_helper"

RSpec.describe SpotifyAuth::FreshAccessToken do
  it "returns the current token while it is valid, without calling Spotify" do
    host = create(:host, access_token: "still-good")

    expect(described_class.call(host)).to eq("still-good")
    expect(a_request(:post, SpotifyHelpers::TOKEN_URL)).not_to have_been_made
  end

  context "when the token has expired" do
    let(:host) { create(:host, :with_expired_spotify_token, refresh_token: "old-refresh") }

    it "renews it and saves the new tokens" do
      stub_spotify_token

      expect(described_class.call(host)).to eq("new-access-token")
      expect(host.reload).to have_attributes(refresh_token: "new-refresh-token", spotify_token_expired?: false)
    end

    it "keeps the old refresh token when Spotify doesn't send a new one" do
      stub_spotify_token({ "access_token" => "renewed", "expires_in" => 3600 })

      described_class.call(host)

      expect(host.reload.refresh_token).to eq("old-refresh")
    end

    it "logs the host out when Spotify access was revoked" do
      HostToken.issue!(host:, kind: :access)
      stub_spotify_token({ "error" => "invalid_grant" }, status: 400)

      expect { described_class.call(host) }.to raise_error(SpotifyAuth::ReauthenticationRequired)
      expect(host.host_tokens).to be_empty
    end
  end
end

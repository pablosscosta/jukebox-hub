require "rails_helper"

RSpec.describe Host do
  describe "Spotify tokens" do
    it "stores them encrypted in the database" do
      host = create(:host, access_token: "plain-access", refresh_token: "plain-refresh")

      raw = described_class.connection.select_one("SELECT access_token, refresh_token FROM hosts WHERE id = #{host.id}")

      expect(raw.values).not_to include("plain-access", "plain-refresh")
      expect(host.reload).to have_attributes(access_token: "plain-access", refresh_token: "plain-refresh")
    end
  end

  describe "validations" do
    it "does not allow two hosts with the same Spotify user" do
      create(:host, spotify_user_id: "same")

      expect(build(:host, spotify_user_id: "same")).not_to be_valid
    end
  end

  describe "#spotify_token_expired?" do
    it "is false while the token has time left" do
      expect(build(:host, token_expires_at: 10.minutes.from_now)).not_to be_spotify_token_expired
    end

    it "is true a bit before the real expiration" do
      expect(build(:host, token_expires_at: 30.seconds.from_now)).to be_spotify_token_expired
    end
  end
end

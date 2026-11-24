require "rails_helper"

RSpec.describe SpotifyAuth::CompleteLogin do
  subject(:complete_login) { described_class.call(code: "auth-code", code_verifier: "verifier") }

  before { stub_spotify_token }

  it "creates the host with the Spotify tokens and returns a login code for them" do
    stub_spotify_me

    login_code = complete_login

    host = Host.find_by!(spotify_user_id: "spotify-user-1")
    expect(host).to have_attributes(display_name: "Pablo", access_token: "new-access-token",
                                    refresh_token: "new-refresh-token")
    expect(HostToken.consume_login_code(login_code)).to eq(host)
  end

  it "updates the existing host instead of creating another one" do
    host = create(:host, spotify_user_id: "spotify-user-1", display_name: "Old name")
    stub_spotify_me

    expect { complete_login }.not_to change(Host, :count)
    expect(host.reload).to have_attributes(display_name: "Pablo", access_token: "new-access-token")
  end

  it "saves the Spotify plan, refreshed on every login" do
    create(:host, spotify_user_id: "spotify-user-1", product: "free")
    stub_spotify_me({ "id" => "spotify-user-1", "display_name" => "Pablo", "product" => "premium" })

    complete_login

    expect(Host.last).to be_premium
  end

  it "uses the Spotify id as name when the profile has no display name" do
    stub_spotify_me({ "id" => "spotify-user-1", "display_name" => nil })

    complete_login

    expect(Host.last.display_name).to eq("spotify-user-1")
  end

  it "saves nothing when the profile request fails" do
    stub_spotify_me({}, status: 500)

    expect { complete_login }.to raise_error(Spotify::Error)
    expect(Host.count).to eq(0)
  end
end

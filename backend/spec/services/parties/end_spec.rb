require "rails_helper"

RSpec.describe Parties::End do
  let(:party) { create(:party) }
  let(:spotify) { Spotify::ApiClient.new(access_token: "host-access-token") }
  let!(:playing) { create(:queue_item, :playing, participant: create(:participant, party:)) }

  before { stub_spotify_pause }

  it "ends the party and stops the music when the host ends it" do
    described_class.call(party:, spotify:)

    expect(party.reload).to be_ended
    expect(playing.reload).to be_played
    expect(a_request(:put, SpotifyHelpers::PAUSE_URL).with(query: { "device_id" => party.device_id }))
      .to have_been_made
  end

  it "doesn't touch the host's Spotify when the party just expired" do
    described_class.call(party:)

    expect(party.reload).to be_ended
    expect(a_request(:put, SpotifyHelpers::PAUSE_URL).with(query: hash_including({}))).not_to have_been_made
  end

  it "ends the party even if Spotify can't pause" do
    stub_spotify_pause(status: 404)

    described_class.call(party:, spotify:)

    expect(party.reload).to be_ended
  end

  it "does nothing for a party that already ended" do
    party.ended!

    described_class.call(party:, spotify:)

    expect(a_request(:put, SpotifyHelpers::PAUSE_URL).with(query: hash_including({}))).not_to have_been_made
  end
end

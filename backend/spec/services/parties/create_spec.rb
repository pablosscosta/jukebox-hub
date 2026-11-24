require "rails_helper"

RSpec.describe Parties::Create do
  let(:host) { create(:host) }
  let(:spotify) { Spotify::ApiClient.new(access_token: "host-access-token") }

  def create_party(name: "Churrasco", device_id: "device-1")
    described_class.call(host:, name:, device_id:, spotify:)
  end

  before { stub_spotify_devices([spotify_device(id: "device-1", name: "pablo-note")]) }

  it "creates an active party on the chosen device" do
    party = create_party(name: "  Churrasco  ")

    expect(party).to be_persisted
    expect(party).to have_attributes(host:, name: "Churrasco", device_id: "device-1", device_name: "pablo-note",
                                     status: "active")
  end

  it "requires Spotify Premium" do
    host.update!(product: "free")

    expect { create_party }.to raise_error(described_class::PremiumRequired)
    expect(Party.count).to eq(0)
  end

  it "rejects a device the host doesn't have open" do
    expect { create_party(device_id: "someone-else") }.to raise_error(described_class::DeviceUnavailable)
  end

  it "rejects a restricted device" do
    stub_spotify_devices([spotify_device(id: "device-1", is_restricted: true)])

    expect { create_party }.to raise_error(described_class::DeviceUnavailable)
  end

  it "refuses a second party and points to the current one" do
    current = create(:party, host:)

    expect { create_party }.to raise_error(described_class::ActivePartyExists) { |error|
      expect(error.party).to eq(current)
    }
  end

  it "doesn't call Spotify when the host already has a party" do
    create(:party, host:)

    expect { create_party }.to raise_error(described_class::ActivePartyExists)
    expect(a_request(:get, SpotifyHelpers::DEVICES_URL)).not_to have_been_made
  end

  it "ends an expired party and creates the new one" do
    expired = create(:party, :expired, host:)

    party = create_party

    expect(expired.reload).to be_ended
    expect(host.current_party).to eq(party)
  end

  it "answers ActivePartyExists when another request created a party in the meantime" do
    current = create(:party, host:)
    allow(host).to receive(:current_party).and_return(nil, current)

    expect { create_party }.to raise_error(described_class::ActivePartyExists) { |error|
      expect(error.party).to eq(current)
    }
  end

  it "rejects an invalid name" do
    expect { create_party(name: " ") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

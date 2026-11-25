require "rails_helper"

RSpec.describe "GET /parties/:id/events" do
  let(:party) { create(:party) }
  let(:queue) { Thread::Queue.new }

  before { allow(PartyEvents::Listener.instance).to receive(:subscribe).and_return(queue) }

  def events_in(body)
    body.scan(/^event: (\w+)$/).flatten
  end

  it "streams the party's notices, without needing a token" do
    queue << "queue_changed" << "party_ended"

    get "/parties/#{party.id}/events"

    expect(response.media_type).to eq("text/event-stream")
    expect(events_in(response.body)).to eq(%w[connected queue_changed party_ended])
  end

  it "sends a heartbeat while nothing happens and closes after a while" do
    stub_const("EventsController::HEARTBEAT", 0.seconds)
    stub_const("EventsController::MAX_LIFETIME", 0.05.seconds)

    get "/parties/#{party.id}/events"

    expect(response.body).to include(": heartbeat")
  end

  it "says right away when the party is already over" do
    party.ended!

    get "/parties/#{party.id}/events"

    expect(events_in(response.body)).to eq(%w[party_ended])
  end

  it "answers 404 for a party that doesn't exist" do
    get "/parties/#{SecureRandom.uuid}/events"

    expect(response).to have_http_status(:not_found)
  end
end

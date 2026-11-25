require "rails_helper"

RSpec.describe PartyEvents::Stream do
  let(:queue) { Thread::Queue.new }

  before { allow(PartyEvents::Listener.instance).to receive_messages(subscribe: queue, unsubscribe: nil) }

  def stream(**)
    described_class.new(party_id: "party-1", ended: false, heartbeat: 0.seconds, lifetime: 0.05.seconds,
                        **)
  end

  def chunks(body)
    body.enum_for(:each).to_a
  end

  it "says hello, then relays the party's notices" do
    queue << "queue_changed"

    expect(chunks(stream).first(2)).to eq(["event: connected\ndata: {}\n\n", "event: queue_changed\ndata: {}\n\n"])
  end

  it "sends heartbeats while nothing happens, and calls back on each one" do
    beats = 0

    sent = chunks(stream(on_heartbeat: -> { beats += 1 }))

    expect(sent).to include(": heartbeat\n\n")
    expect(beats).to be_positive
  end

  it "stops after the party ended" do
    queue << "party_ended" << "queue_changed"

    expect(chunks(stream).last).to eq("event: party_ended\ndata: {}\n\n")
  end

  it "only says the party ended when it's already over" do
    expect(chunks(stream(ended: true))).to eq(["event: party_ended\ndata: {}\n\n"])
  end

  it "stops listening when the stream ends" do
    chunks(stream)

    expect(PartyEvents::Listener.instance).to have_received(:unsubscribe).with("party-1", queue)
  end
end

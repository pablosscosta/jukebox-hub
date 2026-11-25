require "rails_helper"

RSpec.describe PartyEvents::Listener do
  # A fresh instance per example, without starting the LISTEN thread.
  subject(:listener) { described_class.send(:new, autostart: false) }

  def notice(party_id, event)
    { partyId: party_id, event: }.to_json
  end

  it "hands a notice to every stream of the party" do
    first = listener.subscribe("party-1")
    second = listener.subscribe("party-1")

    listener.deliver(notice("party-1", "queue_changed"))

    expect([first.pop(timeout: 0), second.pop(timeout: 0)]).to eq(%w[queue_changed queue_changed])
  end

  it "doesn't hand it to other parties" do
    other = listener.subscribe("party-2")

    listener.deliver(notice("party-1", "queue_changed"))

    expect(other).to be_empty
  end

  it "stops handing notices to a stream that unsubscribed" do
    queue = listener.subscribe("party-1")
    listener.unsubscribe("party-1", queue)

    listener.deliver(notice("party-1", "queue_changed"))

    expect(queue).to be_empty
  end

  it "ignores a notice it can't read" do
    expect { listener.deliver("not json") }.not_to raise_error
  end

  it "can be stopped, so a reload in development doesn't leave old listeners behind" do
    listener.stop

    expect(listener.instance_variable_get(:@stopped)).to be(true)
  end
end

require "rails_helper"

RSpec.describe ExpirePartiesJob do
  it "ends the parties that expired, and only those" do
    expired = create(:party, :expired)
    running = create(:party)

    described_class.perform_now

    expect([expired.reload, running.reload].map(&:status)).to eq(%w[ended active])
  end
end

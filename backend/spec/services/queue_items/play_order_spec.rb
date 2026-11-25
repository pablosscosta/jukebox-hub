require "rails_helper"

RSpec.describe QueueItems::PlayOrder do
  let(:song_class) { Struct.new(:name, :participant_id) }

  # "a1" is Ana's first song, "b2" is Bruno's second, and so on.
  def play_order(*names, recent: [])
    pending = names.map { |name| song_class.new(name, name[0]) }
    described_class.call(pending:, recent_participant_ids: recent).map(&:name)
  end

  it "keeps arrival order when nobody would get 3 in a row" do
    expect(play_order("a1", "b1", "a2", "c1")).to eq(%w[a1 b1 a2 c1])
  end

  it "allows 2 songs in a row from the same person" do
    expect(play_order("a1", "a2", "b1")).to eq(%w[a1 a2 b1])
  end

  it "moves someone else's song ahead of a third one in a row" do
    expect(play_order("a1", "a2", "a3", "b1")).to eq(%w[a1 a2 b1 a3])
  end

  it "picks the earliest song from someone else" do
    expect(play_order("a1", "a2", "a3", "c1", "b1")).to eq(%w[a1 a2 c1 a3 b1])
  end

  it "spreads a long run from one person among the others" do
    expect(play_order("a1", "a2", "a3", "a4", "a5", "b1", "c1")).to eq(%w[a1 a2 b1 a3 a4 c1 a5])
  end

  it "lets one person's songs keep playing when nobody else has songs waiting" do
    expect(play_order("a1", "a2", "a3")).to eq(%w[a1 a2 a3])
  end

  it "counts the songs that already played" do
    expect(play_order("a1", "b1", recent: %w[a a])).to eq(%w[b1 a1])
  end

  it "only looks at the last 2 songs that played" do
    expect(play_order("a1", "b1", recent: %w[a b a])).to eq(%w[a1 b1])
  end

  it "returns an empty order for an empty queue" do
    expect(play_order).to eq([])
  end
end

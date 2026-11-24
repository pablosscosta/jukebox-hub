require "rails_helper"

RSpec.describe Spotify::Device do
  def device(**attrs)
    described_class.new(id: "device-1", name: "Notebook", type: "Computer", active: false, restricted: false, **attrs)
  end

  describe "#controllable?" do
    it "is true for a regular device" do
      expect(device).to be_controllable
    end

    it "is false for a restricted device" do
      expect(device(restricted: true)).not_to be_controllable
    end

    it "is false for a device without id" do
      expect(device(id: nil)).not_to be_controllable
    end
  end
end

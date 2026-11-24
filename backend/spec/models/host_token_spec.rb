require "rails_helper"

RSpec.describe HostToken do
  let(:host) { create(:host) }

  describe ".issue!" do
    it "stores only the digest of the token" do
      raw = described_class.issue!(host:, kind: :access)

      expect(described_class.last.token_digest).to eq(described_class.digest(raw))
      expect(described_class.where(token_digest: raw)).to be_empty
    end

    it "sets a short life for login codes and a longer one for access tokens" do
      freeze_time do
        described_class.issue!(host:, kind: :login_code)
        described_class.issue!(host:, kind: :access)

        expect(described_class.login_code.last.expires_at).to eq(1.minute.from_now)
        expect(described_class.access.last.expires_at).to eq(7.days.from_now)
      end
    end
  end

  describe ".find_active" do
    it "finds a valid token of the right kind" do
      raw = described_class.issue!(host:, kind: :access)

      expect(described_class.find_active(raw, kind: :access).host).to eq(host)
    end

    it "ignores a token of another kind" do
      raw = described_class.issue!(host:, kind: :login_code)

      expect(described_class.find_active(raw, kind: :access)).to be_nil
    end

    it "ignores an expired token" do
      raw = described_class.issue!(host:, kind: :access)

      travel 8.days do
        expect(described_class.find_active(raw, kind: :access)).to be_nil
      end
    end

    it "returns nil for a blank token" do
      expect(described_class.find_active("", kind: :access)).to be_nil
    end
  end

  describe ".consume_login_code" do
    it "returns the host only the first time" do
      raw = described_class.issue!(host:, kind: :login_code)

      expect(described_class.consume_login_code(raw)).to eq(host)
      expect(described_class.consume_login_code(raw)).to be_nil
    end

    it "rejects an expired code" do
      raw = described_class.issue!(host:, kind: :login_code)

      travel 2.minutes do
        expect(described_class.consume_login_code(raw)).to be_nil
      end
    end
  end

  it "is deleted together with its host" do
    described_class.issue!(host:, kind: :access)

    expect { host.destroy }.to change(described_class, :count).by(-1)
  end
end

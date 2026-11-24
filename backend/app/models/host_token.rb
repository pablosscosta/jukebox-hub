# Random tokens that identify a host to our API (see DigestibleToken).
class HostToken < ApplicationRecord
  include DigestibleToken

  LIFETIMES = {
    "login_code" => 1.minute,
    "access" => 7.days
  }.freeze

  belongs_to :host

  enum :kind, { login_code: "login_code", access: "access" }, validate: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(expires_at: Time.current..) }

  class << self
    # Creates a token and returns the raw value. It is the only time the raw value exists.
    def issue!(host:, kind:)
      raw = generate_token
      create!(host:, kind:, token_digest: digest(raw), expires_at: LIFETIMES.fetch(kind.to_s).from_now)
      raw
    end

    def find_active(raw, kind:)
      return if raw.blank?

      active.find_by(kind:, token_digest: digest(raw))
    end

    # The login code works only once: it is deleted as soon as it is used. Checking the number
    # of deleted rows makes two simultaneous requests with the same code impossible to both win.
    def consume_login_code(raw)
      token = find_active(raw, kind: :login_code)
      return unless token && where(id: token.id).delete_all == 1

      token.host
    end
  end
end

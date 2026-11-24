# A jukebox session: guests add songs to a queue that plays on the host's Spotify device.
class Party < ApplicationRecord
  # Parties are ephemeral (ADR 0002): they expire after this long without activity.
  LIFETIME = 6.hours
  NAME_MAX_LENGTH = 60

  belongs_to :host
  has_many :participants, dependent: :delete_all

  enum :status, { active: "active", ended: "ended" }, validate: true

  attribute :expires_at, default: -> { LIFETIME.from_now }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :device_id, :device_name, :expires_at, presence: true
  # Friendly error for the common case; the partial unique index in the database is what
  # really guarantees it when two requests arrive at the same time.
  validates :host_id, uniqueness: { conditions: -> { active }, message: :already_has_active_party }, if: :active?

  def expired?
    expires_at <= Time.current
  end

  # Accepts guests and songs. An expired party still marked active is already over for them.
  def open?
    active? && !expired?
  end
end

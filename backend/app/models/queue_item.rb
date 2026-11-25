# A song someone added to the party. It waits as "pending", becomes "playing" and ends as
# "played" (or "removed"). The order in which pending songs play is not stored: QueueItems::PlayOrder
# calculates it every time.
class QueueItem < ApplicationRecord
  # How many songs each participant (host included) may have waiting at the same time.
  MAX_PENDING_PER_PARTICIPANT = 5

  belongs_to :party
  belongs_to :participant

  # Any change to the queue reaches the open screens (see PartyEvents).
  after_save { PartyEvents.publish(party_id, "queue_changed") }

  enum :status, { pending: "pending", playing: "playing", played: "played", removed: "removed" }, validate: true

  validates :track_id, :title, :artist, presence: true
  validates :duration_ms, numericality: { only_integer: true, greater_than: 0 }

  # Arrival order: the id breaks ties between songs added in the same instant.
  scope :in_arrival_order, -> { order(:created_at, :id) }
  # Songs that already started, most recent first.
  scope :recently_started, -> { where(status: %i[playing played]).where.not(started_at: nil).order(started_at: :desc) }
end

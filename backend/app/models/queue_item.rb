class QueueItem < ApplicationRecord
  belongs_to :session

  validates :track_id, presence: true
  validates :status, inclusion: { in: %w[Pending Playing Played] }

  def mark_as_played!
    update(status: "Played", played_at: Time.current)
  end
end

# A jukebox session: guests add songs to a queue that plays on the host's Spotify device.
class Party < ApplicationRecord
  # Parties are ephemeral (ADR 0002): they expire after this long without activity.
  LIFETIME = 6.hours
  NAME_MAX_LENGTH = 60

  belongs_to :host
  has_many :participants, dependent: :delete_all
  has_many :queue_items, dependent: :delete_all

  enum :status, { active: "active", ended: "ended" }, validate: true

  attribute :expires_at, default: -> { LIFETIME.from_now }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :device_id, :device_name, :expires_at, presence: true
  # Friendly error for the common case; the partial unique index in the database is what
  # really guarantees it when two requests arrive at the same time.
  validates :host_id, uniqueness: { conditions: -> { active }, message: :already_has_active_party }, if: :active?

  # playing: a song from the queue. external: a song the host played straight from the Spotify app.
  # paused: Spotify stopped in the middle of a song (e.g. it was closed) and waits for "Tocar".
  # idle: nothing to play, or waiting for the first song.
  def playback_state
    return "paused" if playback_paused?
    return "external" if external_track

    queue_items.playing.exists? ? "playing" : "idle"
  end

  # What the jukebox is following on Spotify right now. A CheckPlaybackJob carries the key it was
  # scheduled for, and does nothing once the party moved on to something else.
  def playback_watch_key
    item_id = queue_items.playing.pick(:id)
    return "item:#{item_id}" if item_id

    "track:#{external_track['trackId']}" if external_track
  end

  # Claims the right to ask Spotify what is playing, at most once per interval. The conditional
  # UPDATE makes it atomic: when many people open the queue at once, only one request wins.
  def claim_playback_check!(interval) # rubocop:disable Naming/PredicateMethod
    # One UPDATE on purpose (no validations, no callbacks): the database settles who got it.
    claimed = Party.where(id:)
                   .where("playback_checked_at IS NULL OR playback_checked_at < ?", interval.ago)
                   .update_all(playback_checked_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    claimed == 1
  end

  def now_playing
    queue_items.playing.includes(:participant).first
  end

  # Pending songs in the order they will play (see QueueItems::PlayOrder).
  def up_next
    recent = queue_items.recently_started.limit(QueueItems::PlayOrder::MAX_IN_A_ROW).pluck(:participant_id)
    QueueItems::PlayOrder.call(pending: queue_items.pending.includes(:participant).in_arrival_order,
                               recent_participant_ids: recent)
  end

  # The host's own participant row, created the first time they need it (e.g. to add a song).
  # The unique index on (party, host role) settles two requests creating it at once.
  def host_participant
    participants.host.create_or_find_by!(role: :host) do |participant|
      participant.display_name = host.display_name.to_s.truncate(Participant::NAME_MAX_LENGTH)
    end
  end

  def expired?
    expires_at <= Time.current
  end

  # Accepts guests and songs. An expired party still marked active is already over for them.
  def open?
    active? && !expired?
  end
end

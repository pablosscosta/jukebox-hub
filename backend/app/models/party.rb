# A jukebox session: guests add songs to a queue that plays on the host's Spotify device.
class Party < ApplicationRecord
  # Parties are ephemeral (ADR 0002): they expire after this long without activity, and their data
  # is deleted a while after they end.
  LIFETIME = 6.hours
  KEEP_ENDED_FOR = 24.hours
  NAME_MAX_LENGTH = 60

  belongs_to :host
  has_many :participants, dependent: :delete_all
  has_many :queue_items, dependent: :delete_all

  enum :status, { active: "active", ended: "ended" }, validate: true

  # Still marked active, but past the expiration: ExpirePartiesJob closes them.
  scope :overdue, -> { active.where(expires_at: ...Time.current) }
  scope :ended_long_ago, -> { ended.where(ended_at: ...KEEP_ENDED_FOR.ago) }

  before_save -> { self.ended_at ||= Time.current }, if: -> { will_save_change_to_status? && ended? }
  # The open screens follow what plays and learn when the party is over (see PartyEvents).
  after_save :publish_changes

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

  # Each song added or started pushes the expiration forward: a lively party never expires mid-song.
  def extend_lifetime!
    update!(expires_at: LIFETIME.from_now)
  end

  def expired?
    expires_at <= Time.current
  end

  # Accepts guests and songs. An expired party still marked active is already over for them.
  def open?
    active? && !expired?
  end

  private

  def publish_changes
    if saved_change_to_status? && ended?
      PartyEvents.publish(id, "party_ended")
    elsif saved_change_to_external_track? || saved_change_to_playback_paused?
      PartyEvents.publish(id, "queue_changed")
    end
  end
end

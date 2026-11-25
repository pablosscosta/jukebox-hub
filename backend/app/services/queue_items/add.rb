module QueueItems
  # A participant adds a song to the party queue.
  class Add
    class InvalidTrack < StandardError; end
    class AlreadyQueued < StandardError; end
    class LimitReached < StandardError; end

    # Spotify track ids are 22 letters and digits. Checking it first keeps anything else out of
    # the URL we call.
    TRACK_ID_FORMAT = /\A[0-9A-Za-z]{22}\z/

    def self.call(...) = new(...).call

    def initialize(participant:, track_id:, spotify:)
      @participant = participant
      @party = participant.party
      @track_id = track_id.to_s
      @spotify = spotify
    end

    def call
      track = find_track
      # Locking the party row makes adds to the same party happen one at a time. Without it, two
      # songs sent together could both pass the "5 pending" check. Spotify is called before the
      # lock, so the lock is never held while waiting on the network.
      @party.with_lock do
        check_limit!
        check_duplicate!
        @party.queue_items.create!(participant: @participant, track_id: track.id, title: track.title,
                                   artist: track.artist, duration_ms: track.duration_ms, image_url: track.image_url)
      end
    rescue ActiveRecord::RecordNotUnique
      # The unique index caught a duplicate the check above didn't see.
      raise AlreadyQueued
    end

    private

    # Title, artist and cover come from Spotify, never from the request, so nobody can put a fake
    # name in the queue.
    def find_track
      raise InvalidTrack unless TRACK_ID_FORMAT.match?(@track_id)

      @spotify.track(@track_id) || raise(InvalidTrack)
    end

    def check_limit!
      raise LimitReached if @participant.queue_items.pending.count >= QueueItem::MAX_PENDING_PER_PARTICIPANT
    end

    def check_duplicate!
      raise AlreadyQueued if @party.queue_items.exists?(status: %i[pending playing], track_id: @track_id)
    end
  end
end

module Playback
  # Moves the party to the next song in the fair order and starts it on the host's device.
  #
  # Callers say which song they think is playing (expected_current_id, nil for "nothing"). If that
  # is no longer true, someone else already moved the queue and this call does nothing. That keeps
  # a late job, a double click on "Pular" or two songs added at once from skipping extra songs.
  class Advance
    Result = Data.define(:status, :item)

    def self.call(...) = new(...).call

    def initialize(party:, spotify:, expected_current_id:)
      @party = party
      @spotify = spotify
      @expected_current_id = expected_current_id
    end

    # Returns a Result with status :playing, :idle (nothing left to play), :stale (the queue
    # already moved) or :device_unavailable (Spotify isn't open on the party's device).
    #
    # Spotify is called inside the party lock: the lock only covers one party, and it is what makes
    # "check what is playing, then play the next one" a single step.
    def call
      @party.with_lock do
        current = @party.now_playing
        next Result.new(:stale, current) unless current&.id == @expected_current_id

        current&.played!
        # Whatever the host played straight from Spotify gives way to the queue.
        @party.update!(external_track: nil)
        start(@party.up_next.first)
      end
    end

    private

    def start(item)
      return Result.new(:idle, nil) unless item

      @spotify.play(device_id: @party.device_id, track_id: item.track_id)
      item.update!(status: :playing, started_at: Time.current)
      @party.update!(playback_paused: false)
      # The job is stored in the same Postgres (Solid Queue), so it is saved in this transaction:
      # either the song starts and its check is scheduled, or neither happens.
      CheckPlaybackJob.schedule_for(item)
      Result.new(:playing, item)
    rescue Spotify::DeviceNotFoundError
      # The song stays pending; the host opens Spotify on the device and presses "Tocar".
      Result.new(:device_unavailable, nil)
    end
  end
end

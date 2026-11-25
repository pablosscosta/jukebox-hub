module Playback
  # Compares what the jukebox thinks is playing with what Spotify is really playing, and reacts.
  # Used by CheckPlaybackJob (near the end of each song) and when someone opens the queue.
  #
  # ending: the caller knows the song was about to end (the job checks again right after the end).
  # Then a different song on Spotify means "ours ended" (Spotify's autoplay may be playing a
  # suggestion); before that, it means the host played something from the Spotify app.
  class Reconcile
    # :unchanged when the song being followed is still on (playing or paused); :changed otherwise.
    Result = Data.define(:status, :playback)

    # Right after the jukebox tells Spotify to play, Spotify may still report the old state for a
    # second or two. Within this window a mismatch means nothing yet.
    STARTUP_GRACE = 10.seconds

    def self.call(...) = new(...).call

    def initialize(party:, spotify:, ending: false)
      @party = party
      @spotify = spotify
      @ending = ending
    end

    def call
      @playback = @spotify.playback
      item = @party.now_playing
      status = if item then reconcile_queue_song(item)
               elsif @party.external_track then reconcile_external
               else :unchanged
               end
      Result.new(status, @playback)
    end

    private

    def reconcile_queue_song(item)
      return :unchanged if just_started?(item) || still_on?(item.track_id)

      if song_ended?(item)
        Advance.call(party: @party, spotify: @spotify, expected_current_id: item.id)
      elsif spotify_stopped?
        # Spotify stopped in the middle of the song (closed, or stopped on another song).
        Stop.call(party: @party, expected_current_id: item.id)
      else
        FollowExternal.call(party: @party, playback: @playback, expected_watch_key: "item:#{item.id}")
      end
      :changed
    end

    def song_ended?(item)
      @ending || @playback&.track_id == item.track_id
    end

    def spotify_stopped?
      @playback.nil? || !@playback.playing
    end

    def reconcile_external
      track_id = @party.external_track["trackId"]
      return :unchanged if still_on?(track_id)

      if @playback&.playing && @playback.track && !@ending && @playback.track_id != track_id
        # The host played yet another song: follow that one instead.
        FollowExternal.call(party: @party, playback: @playback, expected_watch_key: "track:#{track_id}")
      else
        Advance.call(party: @party, spotify: @spotify, expected_current_id: nil)
      end
      :changed
    end

    def just_started?(item)
      item.started_at.present? && item.started_at > STARTUP_GRACE.ago
    end

    def still_on?(track_id)
      @playback&.track_id == track_id && !@playback.finished?
    end
  end
end

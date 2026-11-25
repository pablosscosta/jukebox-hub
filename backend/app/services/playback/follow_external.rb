module Playback
  # The host played a song straight from the Spotify app. The jukebox doesn't fight it: the song it
  # was playing counts as played, the host's song shows as playing, and the queue resumes when it
  # ends (CheckPlaybackJob is scheduled for that).
  class FollowExternal
    def self.call(...) = new(...).call

    # expected_watch_key: what the caller saw the party following (see Party#playback_watch_key).
    def initialize(party:, playback:, expected_watch_key:)
      @party = party
      @playback = playback
      @expected_watch_key = expected_watch_key
    end

    def call
      @party.with_lock do
        next unless @party.playback_watch_key == @expected_watch_key

        @party.now_playing&.played!
        @party.update!(external_track: track_json, playback_paused: false)
        CheckPlaybackJob.schedule_after(@party, "track:#{@playback.track_id}", @playback)
      end
    end

    private

    def track_json
      track = @playback.track
      # When it started, from how far it already went: lets the screens draw its progress.
      started_at = Time.current - @playback.progress_ms.fdiv(1000).seconds
      { trackId: track.id, title: track.title, artist: track.artist, durationMs: track.duration_ms,
        imageUrl: track.image_url, startedAt: started_at.iso8601(3) }
    end
  end
end

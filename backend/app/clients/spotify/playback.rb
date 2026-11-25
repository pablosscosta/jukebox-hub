module Spotify
  # What the host's Spotify is doing right now, as far as the jukebox cares. The track is nil when
  # Spotify plays something that isn't a song (an ad, for example).
  Playback = Data.define(:track, :playing, :progress_ms) do
    def self.from_api(attrs)
      item = attrs["item"]
      new(track: item && item["type"] != "episode" ? Track.from_api(item) : nil,
          playing: attrs["is_playing"] == true, progress_ms: attrs["progress_ms"].to_i)
    end

    def track_id
      track&.id
    end

    def remaining_ms
      [track&.duration_ms.to_i - progress_ms, 0].max
    end

    # Spotify stops at the end of a single song and rewinds it to 0.
    def finished?
      !playing && progress_ms.zero?
    end
  end
end

module Spotify
  # A song as the jukebox needs it: enough to show it in the queue and to play it later.
  Track = Data.define(:id, :title, :artist, :duration_ms, :image_url) do
    def self.from_api(attrs)
      new(id: attrs.fetch("id"), title: attrs.fetch("name"),
          artist: attrs.fetch("artists", []).pluck("name").join(", "),
          duration_ms: attrs.fetch("duration_ms"), image_url: cover_url(attrs.dig("album", "images")))
    end

    # Album covers come in a few sizes (usually 640, 300 and 64 px). The one closest to 300 px looks
    # sharp in a list on a phone screen without downloading the large one.
    def self.cover_url(images)
      return if images.blank?

      images.min_by { |image| (image["width"].to_i - 300).abs }["url"]
    end
  end
end

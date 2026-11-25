require "rails_helper"

RSpec.describe Spotify::Track do
  describe ".from_api" do
    it "keeps what the jukebox needs" do
      track = described_class.from_api(spotify_track)

      expect(track).to eq(described_class.new(id: "track-1", title: "Garota de Ipanema", artist: "Tom Jobim",
                                              duration_ms: 323_000, image_url: "https://i.scdn.co/image/300"))
    end

    it "joins the names when there is more than one artist" do
      artists = [{ "name" => "Stan Getz" }, { "name" => "João Gilberto" }]

      expect(described_class.from_api(spotify_track(artists:)).artist).to eq("Stan Getz, João Gilberto")
    end

    it "uses the closest size when there is no 300 px cover" do
      images = [{ "url" => "https://i.scdn.co/image/640", "width" => 640 },
                { "url" => "https://i.scdn.co/image/64", "width" => 64 }]

      expect(described_class.from_api(spotify_track(album: { "images" => images })).image_url)
        .to eq("https://i.scdn.co/image/64")
    end

    it "has no image when the album has no cover" do
      expect(described_class.from_api(spotify_track(album: { "images" => [] })).image_url).to be_nil
    end
  end
end

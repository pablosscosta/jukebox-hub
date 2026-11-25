module Playback
  # The host took over their Spotify (played something else): the jukebox steps aside. The song it
  # was playing counts as played, and nothing more plays until the host presses "Tocar".
  class Stop
    def self.call(...) = new(...).call

    def initialize(party:, expected_current_id:)
      @party = party
      @expected_current_id = expected_current_id
    end

    def call
      @party.with_lock do
        current = @party.now_playing
        next unless current&.id == @expected_current_id

        current.played!
        @party.update!(playback_paused: true)
      end
    end
  end
end

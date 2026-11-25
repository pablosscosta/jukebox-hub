module Parties
  # Ends a party: by the host ("Encerrar"), or by ExpirePartiesJob when it expires. The open screens
  # learn it right away (PartyEvents), and the party becomes read-only.
  class End
    def self.call(...) = new(...).call

    # spotify: given when the host ends the party, to stop the music too. An expired party doesn't
    # touch the host's Spotify: they may be listening to something else by then.
    def initialize(party:, spotify: nil)
      @party = party
      @spotify = spotify
    end

    def call
      ended_now = @party.with_lock do
        next false if @party.ended?

        @party.now_playing&.played!
        @party.update!(status: :ended, external_track: nil)
        true
      end
      stop_music if ended_now
    end

    private

    def stop_music
      @spotify&.pause(device_id: @party.device_id)
    rescue Spotify::Error => e
      # Already paused, or the device is gone: the party is over either way.
      Rails.logger.info("[parties] could not pause party #{@party.id}: #{e.class}")
    end
  end
end

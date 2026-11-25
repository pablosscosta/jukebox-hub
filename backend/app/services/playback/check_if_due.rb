module Playback
  # While someone is looking at the party (opening the queue, or with the live stream open), the
  # jukebox also looks at Spotify, e.g. to notice a song the host played straight from the Spotify
  # app. At most once per interval for the whole party, however many screens are open.
  class CheckIfDue
    INTERVAL = 20.seconds

    def self.call(party)
      return unless %w[playing external].include?(party.playback_state)
      return unless party.claim_playback_check!(INTERVAL)

      spotify = Spotify::ApiClient.new(access_token: SpotifyAuth::FreshAccessToken.call(party.host))
      Reconcile.call(party:, spotify:)
    rescue Spotify::Error, SpotifyAuth::ReauthenticationRequired => e
      # Looking at Spotify is a bonus: if it fails, the screens show what the jukebox already knows.
      Rails.logger.warn("[playback] check failed for party #{party.id}: #{e.class}")
    end
  end
end

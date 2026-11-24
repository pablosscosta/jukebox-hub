module SpotifyAuth
  # The host's Spotify authorization is gone and they need to log in again.
  class ReauthenticationRequired < StandardError; end
end

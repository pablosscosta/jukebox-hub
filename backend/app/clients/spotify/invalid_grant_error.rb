module Spotify
  # Spotify refused the authorization code or the refresh token (expired, already used or
  # revoked by the user). The only way out is logging in again.
  class InvalidGrantError < Error; end
end

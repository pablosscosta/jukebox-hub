module Spotify
  # Tokens returned by Spotify. On refresh Spotify may not send a new refresh_token, in which
  # case it is nil and the old one is still valid.
  TokenSet = Data.define(:access_token, :refresh_token, :expires_at)
end

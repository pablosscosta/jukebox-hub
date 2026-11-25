module Spotify
  # Spotify can't reach the device: the app was closed there, or it went offline.
  class DeviceNotFoundError < Error; end
end

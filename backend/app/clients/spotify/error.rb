module Spotify
  # Any failure talking to Spotify (network, unexpected status, bad response).
  class Error < StandardError
    attr_reader :status

    def initialize(message = nil, status: nil)
      super(message)
      @status = status
    end
  end
end

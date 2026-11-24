module Spotify
  # A Spotify Connect device (phone, computer, speaker) where the host's music can play.
  Device = Data.define(:id, :name, :type, :active, :restricted) do
    def self.from_api(attrs)
      new(id: attrs["id"], name: attrs.fetch("name"), type: attrs.fetch("type"),
          active: attrs["is_active"] == true, restricted: attrs["is_restricted"] == true)
    end

    # Restricted devices (and the few that come without an id) don't accept playback
    # commands from the Web API, so there is no point in offering them to the host.
    def controllable?
      id.present? && !restricted
    end
  end
end

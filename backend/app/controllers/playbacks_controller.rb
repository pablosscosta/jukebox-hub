# The host's controls over what plays. Moving the queue on its own (when a song ends) is
# CheckPlaybackJob's job; these are the host's manual buttons.
class PlaybacksController < ApplicationController
  include PartyScoped

  before_action :require_open_party, :authenticate_participant!, :require_host!

  # POST /parties/:party_id/playback/next
  # Skips the song that is playing. Sends the id of the song the host saw playing, so a double click
  # doesn't skip two songs.
  def next_track
    advance(expected_current_id: @party.now_playing&.id)
  end

  # POST /parties/:party_id/playback/start
  # Starts the queue when nothing is playing: after the host paused the jukebox, or when Spotify
  # wasn't open on the device.
  def start
    advance(expected_current_id: nil)
  end

  private

  def advance(expected_current_id:)
    result = Playback::Advance.call(party: @party, spotify: spotify_api(@party.host), expected_current_id:)
    if result.status == :device_unavailable
      return render_error("device_unavailable",
                          "O Spotify não está aberto em #{@party.device_name}. Abra o Spotify nele e toque de novo.",
                          status: :unprocessable_content)
    end

    head :no_content
  end
end

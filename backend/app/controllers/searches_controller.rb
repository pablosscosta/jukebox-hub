# Song search for anyone in the party. Guests have no Spotify account, so the search runs with
# the host's Spotify token.
class SearchesController < ApplicationController
  include PartyScoped

  QUERY_MAX_LENGTH = 100

  before_action :require_open_party, :authenticate_participant!

  # Here the caller is usually a guest: "log in again" would make no sense to them, the one who
  # needs to reconnect is the host.
  rescue_from SpotifyAuth::ReauthenticationRequired do
    render_error("host_spotify_disconnected", "O Spotify do host desconectou. Peça para o host entrar de novo.",
                 status: :service_unavailable)
  end

  # GET /parties/:party_id/search?q=
  def show
    query = params[:q].to_s.strip
    if query.empty? || query.length > QUERY_MAX_LENGTH
      return render_error("invalid_query", "Digite de 1 a #{QUERY_MAX_LENGTH} caracteres para buscar.",
                          status: :unprocessable_content)
    end

    tracks = spotify_api(@party.host).search_tracks(query)
    render json: tracks.map { |track| track_json(track) }
  end

  private

  def track_json(track)
    { trackId: track.id, title: track.title, artist: track.artist, durationMs: track.duration_ms,
      imageUrl: track.image_url }
  end
end

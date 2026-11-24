class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  rescue_from SpotifyAuth::ReauthenticationRequired do
    render_error("unauthorized", "Sua conexão com o Spotify expirou. Faça login de novo.", status: :unauthorized)
  end

  rescue_from Spotify::Error do |error|
    Rails.logger.warn("[spotify] #{error.class}: #{error.message}")
    render_error("spotify_unavailable", "Não foi possível falar com o Spotify. Tente de novo.",
                 status: :bad_gateway)
  end

  private

  # Spotify Web API client acting as the logged-in host, with a token that is still valid.
  def spotify_api
    Spotify::ApiClient.new(access_token: SpotifyAuth::FreshAccessToken.call(current_host))
  end

  # Every error follows the same shape: { "error": { "code": "...", "message": "..." } }.
  def render_error(code, message, status:)
    render json: { error: { code:, message: } }, status:
  end

  # Reads "Authorization: Bearer <token>" and loads the host it belongs to.
  def authenticate_host!
    @current_host_token = authenticate_with_http_token do |token, _options|
      HostToken.find_active(token, kind: :access)
    end
    return if @current_host_token

    render_error("unauthorized", "Faça login com o Spotify para continuar.", status: :unauthorized)
  end

  attr_reader :current_host_token

  def current_host
    current_host_token&.host
  end

  def host_json(host)
    { id: host.id.to_s, displayName: host.display_name, premium: host.premium? }
  end

  def render_party_not_found
    render_error("party_not_found", "Não encontramos essa party. Confira o link.", status: :not_found)
  end

  # What anyone with the invite link can see: no device, no link, nothing about the host's account.
  # An expired party that nobody closed yet already shows as ended.
  def public_party_json(party)
    { id: party.id, name: party.name, status: party.open? ? "active" : "ended",
      hostName: party.host.display_name, expiresAt: party.expires_at }
  end

  def participant_json(participant)
    { id: participant.id.to_s, displayName: participant.display_name, joinedAt: participant.created_at }
  end

  # The invite link points to the frontend, where guests join the party.
  def party_json(party)
    {
      id: party.id, name: party.name, status: party.status, deviceName: party.device_name,
      shareUrl: "#{Rails.configuration.x.invite_origin}/p/#{party.id}",
      expiresAt: party.expires_at, createdAt: party.created_at
    }
  end
end

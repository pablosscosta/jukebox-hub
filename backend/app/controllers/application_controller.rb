class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  private

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
    { id: host.id.to_s, displayName: host.display_name }
  end
end

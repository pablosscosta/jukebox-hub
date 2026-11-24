module Auth
  # Turns the one-time login code into the host's access token, and logs out.
  class TokensController < ApplicationController
    before_action :authenticate_host!, only: :destroy

    # POST /auth/token  { "code": "..." }
    def create
      host = HostToken.consume_login_code(params[:code])
      unless host
        return render_error("invalid_login_code", "Código de login inválido ou expirado.",
                            status: :unauthorized)
      end

      token = HostToken.issue!(host:, kind: :access)
      render json: { token:, host: host_json(host) }, status: :created
    end

    # DELETE /auth/token
    def destroy
      current_host_token.destroy!
      head :no_content
    end
  end
end

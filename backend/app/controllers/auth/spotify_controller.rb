module Auth
  # Host login with Spotify (Authorization Code + PKCE). Both actions are full-page browser
  # navigations, not fetch calls: the browser goes to Spotify and comes back.
  class SpotifyController < ApplicationController
    include ActionController::Cookies

    # Keeps state and PKCE verifier between the two requests. Encrypted, so the browser can't
    # read or change it, and tied to this browser, which blocks login CSRF.
    FLOW_COOKIE = :spotify_oauth_flow
    COOKIE_PATH = "/auth/spotify".freeze

    # GET /auth/spotify
    def start
      state = SecureRandom.urlsafe_base64(32)
      verifier = Spotify::Pkce.generate_verifier
      authorize_url = accounts.authorize_url(state:, code_challenge: Spotify::Pkce.challenge_for(verifier))

      store_flow(state:, verifier:)
      redirect_to authorize_url, allow_other_host: true
    rescue Spotify::ConfigurationError => e
      Rails.logger.error("[spotify-auth] #{e.message}")
      redirect_to_frontend(error: "spotify_not_configured")
    end

    # GET /auth/spotify/callback
    def callback
      flow = take_flow
      error = callback_error(flow)
      return redirect_to_frontend(error:) if error

      login_code = SpotifyAuth::CompleteLogin.call(code: params.require(:code), code_verifier: flow["verifier"])
      redirect_to_frontend(code: login_code)
    rescue Spotify::Error, ActionController::ParameterMissing => e
      Rails.logger.warn("[spotify-auth] login failed: #{e.class}: #{e.message}")
      redirect_to_frontend(error: not_allowed?(e) ? "not_allowed" : "login_failed")
    end

    private

    # In Spotify's development mode only accounts listed in the app's dashboard (User Management)
    # can use the API: anyone else logs in on Spotify and then gets 403 from it.
    def not_allowed?(error)
      error.is_a?(Spotify::Error) && error.status == 403
    end

    def accounts
      @accounts ||= Spotify::AccountsClient.new
    end

    def store_flow(state:, verifier:)
      cookies.encrypted[FLOW_COOKIE] = {
        value: { "state" => state, "verifier" => verifier },
        expires: 10.minutes,
        path: COOKIE_PATH,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end

    # Reads the cookie and deletes it right away, so each state works only once.
    def take_flow
      flow = cookies.encrypted[FLOW_COOKIE]
      cookies.delete(FLOW_COOKIE, path: COOKIE_PATH)
      flow
    end

    def callback_error(flow)
      return "access_denied" if params[:error].present?

      "invalid_state" unless valid_state?(flow)
    end

    def valid_state?(flow)
      flow.is_a?(Hash) && params[:state].present? &&
        ActiveSupport::SecurityUtils.secure_compare(flow["state"].to_s, params[:state].to_s)
    end

    def redirect_to_frontend(**query)
      redirect_to "#{Rails.configuration.x.frontend_origin}/auth/callback?#{query.to_query}", allow_other_host: true
    end
  end
end

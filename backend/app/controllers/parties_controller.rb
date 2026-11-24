class PartiesController < ApplicationController
  before_action :authenticate_host!

  rescue_from Parties::Create::PremiumRequired do
    render_error("premium_required", "Para tocar músicas pela Jukebox Hub você precisa do Spotify Premium.",
                 status: :forbidden)
  end

  rescue_from Parties::Create::DeviceUnavailable do
    render_error("device_unavailable", "Esse device não está mais disponível. Abra o Spotify nele e tente de novo.",
                 status: :unprocessable_content)
  end

  rescue_from Parties::Create::ActivePartyExists do |error|
    render json: {
      error: { code: "active_party_exists", message: "Você já tem uma party ativa." },
      party: party_json(error.party)
    }, status: :conflict
  end

  rescue_from ActiveRecord::RecordInvalid do
    render_error("invalid_party", "Dê um nome de até #{Party::NAME_MAX_LENGTH} caracteres para a party.",
                 status: :unprocessable_content)
  end

  # POST /parties
  def create
    party = Parties::Create.call(host: current_host, name: params[:name], device_id: params[:deviceId],
                                 spotify: spotify_api)
    render json: party_json(party), status: :created
  end
end

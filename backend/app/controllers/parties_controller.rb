class PartiesController < ApplicationController
  before_action :authenticate_host!, only: %i[create finish]

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

  # GET /parties/:id (public: what a guest sees before joining)
  def show
    party = Party.includes(:host).find_by(id: params[:id])
    return render_party_not_found unless party

    render json: public_party_json(party)
  end

  # POST /parties
  def create
    party = Parties::Create.call(host: current_host, name: params[:name], device_id: params[:deviceId],
                                 spotify: spotify_api)
    render json: party_json(party), status: :created
  end

  # POST /parties/:id/end
  # The host ends the party: the music stops and every open screen learns it. Ending it again is fine.
  def finish
    party = current_host.parties.find_by(id: params[:id])
    return render_party_not_found unless party

    Parties::End.call(party:, spotify: spotify_api)
    head :no_content
  end
end

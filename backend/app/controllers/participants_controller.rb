class ParticipantsController < ApplicationController
  before_action :set_party
  before_action :require_open_party, only: :me

  rescue_from Participants::Join::PartyClosed do
    render_party_ended
  end

  # POST /parties/:party_id/participants
  def create
    result = Participants::Join.call(party: @party, display_name: params[:displayName])
    render json: { participantToken: result.token, participant: participant_json(result.participant) },
           status: :created
  rescue ActiveRecord::RecordInvalid
    render_error("invalid_participant", "Use um nome de até #{Participant::NAME_MAX_LENGTH} caracteres.",
                 status: :unprocessable_content)
  end

  # GET /parties/:party_id/participants/me
  # Lets a guest who comes back check that the token saved on their phone still works.
  def me
    participant = authenticate_with_http_token { |token, _options| @party.participants.authenticate(token) }
    return render json: participant_json(participant) if participant

    render_error("unauthorized", "Entre na party de novo.", status: :unauthorized)
  end

  private

  def set_party
    @party = Party.find_by(id: params[:party_id])
    render_party_not_found unless @party
  end

  # Once the party is over, guests' tokens stop working too.
  def require_open_party
    render_party_ended unless @party.open?
  end

  # An ended party is read-only (410 Gone): no new guests.
  def render_party_ended
    render_error("party_ended", "Essa party já terminou.", status: :gone)
  end
end

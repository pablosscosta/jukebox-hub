class ParticipantsController < ApplicationController
  include PartyScoped

  before_action :require_open_party, :authenticate_participant!, only: :me

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
  # Lets a guest who comes back check that the token saved on their phone still works. With the
  # host's token it returns the host's own participant.
  def me
    render json: participant_json(current_participant)
  end
end

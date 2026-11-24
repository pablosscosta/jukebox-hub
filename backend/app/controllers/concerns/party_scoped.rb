# For controllers under /parties/:party_id: loads the party and identifies who is calling.
module PartyScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_party
  end

  private

  attr_reader :current_participant

  def set_party
    @party = Party.find_by(id: params[:party_id])
    render_party_not_found unless @party
  end

  # Once the party is over it is read-only, and tokens stop working.
  def require_open_party
    render_party_ended unless @party.open?
  end

  def render_party_ended
    render_error("party_ended", "Essa party já terminou.", status: :gone)
  end

  # Accepts a guest's token or the token of this party's host, who acts as a participant too.
  def authenticate_participant!
    @current_participant = authenticate_with_http_token { |token, _options| participant_for(token) }
    return if @current_participant

    render_error("unauthorized", "Entre na party de novo.", status: :unauthorized)
  end

  def participant_for(token)
    @party.participants.authenticate(token) || host_participant_for(token)
  end

  def host_participant_for(token)
    host_token = HostToken.find_active(token, kind: :access)
    @party.host_participant if host_token && host_token.host_id == @party.host_id
  end
end

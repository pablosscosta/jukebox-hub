module Me
  class PartyController < ApplicationController
    before_action :authenticate_host!

    # GET /me/party
    def show
      party = current_host.current_party
      return render_error("no_active_party", "Você não tem uma party ativa.", status: :not_found) unless party

      render json: party_json(party)
    end
  end
end

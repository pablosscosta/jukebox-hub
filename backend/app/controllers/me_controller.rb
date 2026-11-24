class MeController < ApplicationController
  before_action :authenticate_host!

  # GET /me
  def show
    render json: host_json(current_host)
  end
end

class SessionsController < ApplicationController
  before_action :set_session, only: [:show, :update, :destroy]

  def index
    sessions = Session.order(created_at: :desc)
    render json: sessions
  end

  def show
    render json: @session
  end

  def create
    session = Session.new(session_params)
    if session.save
      render json: session, status: :created
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @session.update(session_params)
      render json: @session
    else
      render json: { errors: @session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @session.update(status: "Ended")
    @session.destroy
    head :no_content
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :host_user_id,
      :device_id,
      :session_name,
      :share_link,
      :qr_code_url,
      :status
    )
  end
end

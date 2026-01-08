class UsersController < ApplicationController
  before_action :set_session

  def index
    users = @session.users.order(created_at: :asc)
    render json: users
  end

  def create
    user = @session.users.new(user_params.merge(joined_at: Time.current))
    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end

  def user_params
    params.require(:user).permit(:display_name)
  end
end

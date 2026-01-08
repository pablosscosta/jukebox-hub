class QueueItemsController < ApplicationController
  before_action :set_session
  before_action :set_queue_item, only: [:update]

  def index
    items = @session.queue_items.order(created_at: :asc)
    render json: items
  end

  def create
    item = @session.queue_items.new(queue_item_params.merge(added_at: Time.current))
    if item.save
      render json: item, status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @queue_item.update(queue_item_params)
      render json: @queue_item
    else
      render json: { errors: @queue_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end

  def set_queue_item
    @queue_item = @session.queue_items.find(params[:id])
  end

  def queue_item_params
    params.require(:queue_item).permit(:track_id, :added_by_user_id, :status)
  end
end

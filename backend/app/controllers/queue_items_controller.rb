class QueueItemsController < ApplicationController
  include PartyScoped

  before_action :require_open_party, :authenticate_participant!

  rescue_from QueueItems::Add::InvalidTrack do
    render_error("invalid_track", "Não encontramos essa música no Spotify.", status: :unprocessable_content)
  end

  rescue_from QueueItems::Add::AlreadyQueued do
    render_error("already_queued", "Essa música já está na fila.", status: :conflict)
  end

  rescue_from QueueItems::Add::LimitReached do
    render_error("queue_limit_reached", "Você já tem #{QueueItem::MAX_PENDING_PER_PARTICIPANT} músicas " \
                                        "esperando. Espere uma tocar para adicionar outra.", status: :conflict)
  end

  # GET /parties/:party_id/queue
  def index
    now_playing = @party.now_playing
    render json: {
      nowPlaying: now_playing && queue_item_json(now_playing),
      upNext: @party.up_next.map { |item| queue_item_json(item) },
      maxPendingPerParticipant: QueueItem::MAX_PENDING_PER_PARTICIPANT
    }
  end

  # POST /parties/:party_id/queue
  def create
    item = QueueItems::Add.call(participant: current_participant, track_id: params[:trackId],
                                spotify: spotify_api(@party.host))
    render json: queue_item_json(item), status: :created
  end

  private

  def queue_item_json(item)
    { id: item.id.to_s, trackId: item.track_id, title: item.title, artist: item.artist,
      durationMs: item.duration_ms, imageUrl: item.image_url, status: item.status,
      addedBy: { id: item.participant_id.to_s, displayName: item.participant.display_name },
      addedAt: item.created_at }
  end
end

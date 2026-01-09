class QueueItemSerializer < ActiveModel::Serializer
  attributes :id, :track_id, :status, :added_at, :played_at
end

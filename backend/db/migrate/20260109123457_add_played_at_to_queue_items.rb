class AddPlayedAtToQueueItems < ActiveRecord::Migration[8.1]
  def change
    add_column :queue_items, :played_at, :datetime
  end
end

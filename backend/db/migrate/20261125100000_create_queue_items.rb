class CreateQueueItems < ActiveRecord::Migration[8.1]
  def change
    create_table :queue_items do |t|
      t.references :party, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :participant, null: false, foreign_key: { on_delete: :cascade }
      # Copied from Spotify when the song is added, so showing the queue never calls Spotify.
      t.string :track_id, null: false
      t.string :title, null: false
      t.string :artist, null: false
      t.integer :duration_ms, null: false
      t.string :image_url
      t.string :status, null: false, default: "pending"
      # When the song started playing: the play order looks at who had the last songs.
      t.datetime :started_at

      t.timestamps
    end

    add_check_constraint :queue_items, "status IN ('pending', 'playing', 'played', 'removed')",
                         name: "queue_items_status_check"
    # The same song can't be in the queue twice. Once it was played (or removed) it can come back.
    add_index :queue_items, %i[party_id track_id], unique: true, where: "status IN ('pending', 'playing')",
                                                   name: "index_queue_items_no_duplicate_tracks"
    add_index :queue_items, :party_id, unique: true, where: "status = 'playing'",
                                       name: "index_queue_items_one_playing_per_party"
  end
end

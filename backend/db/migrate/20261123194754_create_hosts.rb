class CreateHosts < ActiveRecord::Migration[8.1]
  def change
    create_table :hosts do |t|
      t.string :spotify_user_id, null: false
      t.string :display_name
      # Encrypted with Active Record Encryption (see Host).
      t.text :access_token, null: false
      t.text :refresh_token, null: false
      t.datetime :token_expires_at, null: false

      t.timestamps
    end

    add_index :hosts, :spotify_user_id, unique: true
  end
end

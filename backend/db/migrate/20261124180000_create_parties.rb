class CreateParties < ActiveRecord::Migration[8.1]
  def change
    # UUID because the id goes in the invite link: a sequential id would let anyone guess
    # other parties' links. gen_random_uuid() is built into PostgreSQL 13+.
    create_table :parties, id: :uuid do |t|
      t.references :host, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      # Spotify Connect device where the music plays.
      t.string :device_id, null: false
      t.string :status, null: false, default: "active"
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_check_constraint :parties, "status IN ('active', 'ended')", name: "parties_status_check"
    add_check_constraint :parties, "char_length(name) BETWEEN 1 AND 60", name: "parties_name_length_check"
    # A host runs one party at a time. Ended parties don't count, so the host can start a new
    # one after ending the previous one.
    add_index :parties, :host_id, unique: true, where: "status = 'active'", name: "index_parties_one_active_per_host"
  end
end

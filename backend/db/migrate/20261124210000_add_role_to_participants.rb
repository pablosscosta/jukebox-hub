class AddRoleToParticipants < ActiveRecord::Migration[8.1]
  def change
    # The host is also a participant of their own party (to add songs), but they identify
    # themselves with their host token, so their participant row has no token of its own.
    change_table :participants, bulk: true do |t|
      t.string :role, null: false, default: "guest"
      t.change_null :token_digest, true
    end

    add_check_constraint :participants, "role IN ('guest', 'host')", name: "participants_role_check"
    add_check_constraint :participants, "role = 'host' OR token_digest IS NOT NULL",
                         name: "participants_guest_token_check"
    add_index :participants, :party_id, unique: true, where: "role = 'host'",
                                        name: "index_participants_one_host_per_party"
  end
end

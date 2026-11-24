class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :party, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :display_name, null: false
      # Only the SHA-256 digest of the guest's token is stored (see DigestibleToken).
      t.string :token_digest, null: false, index: { unique: true }

      t.timestamps
    end

    add_check_constraint :participants, "char_length(display_name) BETWEEN 1 AND 40",
                         name: "participants_display_name_length_check"
  end
end

class CreateHostTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :host_tokens do |t|
      t.references :host, null: false, foreign_key: { on_delete: :cascade }
      # login_code: one-time code handed to the frontend after the OAuth callback.
      # access: bearer token the frontend sends on every request.
      t.string :kind, null: false
      # Only the SHA-256 digest is stored; the raw token never touches the database.
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :host_tokens, :token_digest, unique: true
    add_check_constraint :host_tokens, "kind IN ('login_code', 'access')", name: "host_tokens_kind_check"
  end
end

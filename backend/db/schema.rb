# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_23_194756) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "host_tokens", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "kind", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_host_tokens_on_host_id"
    t.index ["token_digest"], name: "index_host_tokens_on_token_digest", unique: true
    t.check_constraint "kind::text = ANY (ARRAY['login_code'::character varying, 'access'::character varying]::text[])", name: "host_tokens_kind_check"
  end

  create_table "hosts", force: :cascade do |t|
    t.string "spotify_user_id", null: false
    t.string "display_name"
    t.text "access_token", null: false
    t.text "refresh_token", null: false
    t.datetime "token_expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_user_id"], name: "index_hosts_on_spotify_user_id", unique: true
  end

  add_foreign_key "host_tokens", "hosts", on_delete: :cascade
end

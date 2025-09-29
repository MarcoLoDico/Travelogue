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

ActiveRecord::Schema[8.0].define(version: 2025_09_29_030000) do
  create_table "access_tokens", force: :cascade do |t|
    t.string "token"
    t.string "refresh_token"
    t.datetime "expires_at"
    t.text "scopes"
    t.integer "application_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_access_tokens_on_application_id"
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "authorization_codes", force: :cascade do |t|
    t.string "code", null: false
    t.integer "user_id", null: false
    t.integer "application_id", null: false
    t.string "redirect_uri", null: false
    t.string "scope"
    t.string "nonce"
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_authorization_codes_on_application_id"
    t.index ["code"], name: "index_authorization_codes_on_code", unique: true
    t.index ["user_id"], name: "index_authorization_codes_on_user_id"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name"
    t.string "uid"
    t.string "secret"
    t.text "redirect_uri"
    t.text "scopes"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_oauth_applications_on_user_id"
  end

  create_table "one_time_codes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code"
    t.datetime "expires_at"
    t.boolean "used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_one_time_codes_on_user_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "name"
    t.integer "kind"
    t.string "country_code"
    t.string "admin1_code"
    t.integer "external_id", limit: 8
    t.float "lat"
    t.float "lon"
    t.integer "population", limit: 8
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_places_on_parent_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "place_id", null: false
    t.date "visited_on"
    t.datetime "arrived_at"
    t.datetime "departed_at"
    t.text "notes"
    t.float "lat"
    t.float "lon"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_visits_on_place_id"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  add_foreign_key "access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "authorization_codes", "oauth_applications", column: "application_id"
  add_foreign_key "authorization_codes", "users"
  add_foreign_key "oauth_applications", "users"
  add_foreign_key "one_time_codes", "users"
  add_foreign_key "places", "places", column: "parent_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "visits", "places"
  add_foreign_key "visits", "users"
end

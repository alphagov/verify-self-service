# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_31_100615) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "certificates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "value"
    t.string "usage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "component_id"
    t.boolean "enabled", default: true
    t.string "component_type"
    t.index ["component_id"], name: "index_certificates_on_component_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", null: false
    t.json "data"
    t.string "aggregate_type"
    t.uuid "aggregate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.index ["aggregate_type", "aggregate_id"], name: "index_events_on_aggregate_type_and_aggregate_id"
  end

  create_table "msa_components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "component_type"
    t.uuid "encryption_certificate_id"
    t.string "entity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "team_id"
    t.string "environment", null: false
    t.index ["team_id"], name: "index_msa_components_on_team_id"
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "entity_id", null: false
    t.string "name"
    t.uuid "sp_component_id"
    t.uuid "msa_component_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_services_on_entity_id", unique: true
  end

  create_table "sp_components", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "component_type"
    t.uuid "encryption_certificate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "vsp", default: false
    t.uuid "team_id"
    t.string "environment", null: false
    t.index ["team_id"], name: "index_sp_components_on_team_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "team_alias"
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

end

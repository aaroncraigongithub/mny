# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140608002605) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.boolean  "is_default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id", using: :btree

  create_table "categories", force: true do |t|
    t.integer  "user_id"
    t.integer  "parent_id"
    t.string   "name"
    t.integer  "transaction_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories", ["user_id", "name"], name: "index_categories_on_user_id_and_name", using: :btree
  add_index "categories", ["user_id", "transaction_type"], name: "index_categories_on_user_id_and_transaction_type", using: :btree
  add_index "categories", ["user_id"], name: "index_categories_on_user_id", using: :btree

  create_table "scheduled_transactions", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "transfer_to"
    t.datetime "transaction_at"
    t.text     "repeats"
    t.integer  "amount"
    t.integer  "transaction_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scheduled_transactions", ["account_id"], name: "index_scheduled_transactions_on_account_id", using: :btree
  add_index "scheduled_transactions", ["transaction_at"], name: "index_scheduled_transactions_on_transaction_at", using: :btree
  add_index "scheduled_transactions", ["transaction_type"], name: "index_scheduled_transactions_on_transaction_type", using: :btree
  add_index "scheduled_transactions", ["user_id"], name: "index_scheduled_transactions_on_user_id", using: :btree

  create_table "transaction_endpoints", force: true do |t|
    t.integer  "user_id"
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transaction_endpoints", ["label"], name: "index_transaction_endpoints_on_label", using: :btree
  add_index "transaction_endpoints", ["user_id"], name: "index_transaction_endpoints_on_user_id", using: :btree

  create_table "transactions", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.integer  "transaction_endpoint_id"
    t.integer  "transfer_to"
    t.integer  "transfer_from"
    t.integer  "category_id"
    t.integer  "transaction_type"
    t.integer  "amount"
    t.datetime "transaction_at"
    t.integer  "status",                  default: 0
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["account_id"], name: "index_transactions_on_account_id", using: :btree
  add_index "transactions", ["category_id"], name: "index_transactions_on_category_id", using: :btree
  add_index "transactions", ["status"], name: "index_transactions_on_status", using: :btree
  add_index "transactions", ["transaction_at"], name: "index_transactions_on_transaction_at", using: :btree
  add_index "transactions", ["transaction_endpoint_id"], name: "index_transactions_on_transaction_endpoint_id", using: :btree
  add_index "transactions", ["transaction_type"], name: "index_transactions_on_transaction_type", using: :btree
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end

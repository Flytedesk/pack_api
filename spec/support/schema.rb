# frozen_string_literal: true

# Define the schema for test models
ActiveRecord::Schema.define do
  # Active Storage tables
  create_table :active_storage_blobs, force: true do |t|
    t.string   :key,          null: false
    t.string   :filename,     null: false
    t.string   :content_type
    t.text     :metadata
    t.string   :service_name, null: false
    t.bigint   :byte_size,    null: false
    t.string   :checksum
    t.datetime :created_at,   null: false
    t.index [:key], unique: true
  end

  create_table :active_storage_attachments, force: true do |t|
    t.string     :name,     null: false
    t.references :record,   null: false, polymorphic: true, index: false
    t.references :blob,     null: false
    t.datetime :created_at, null: false
    t.index [:record_type, :record_id, :name, :blob_id], name: "index_active_storage_attachments_uniqueness", unique: true
    t.foreign_key :active_storage_blobs, column: :blob_id
  end

  create_table :active_storage_variant_records, force: true do |t|
    t.belongs_to :blob, null: false, index: false
    t.string :variation_digest, null: false
    t.index [:blob_id, :variation_digest], name: "index_active_storage_variant_records_uniqueness", unique: true
    t.foreign_key :active_storage_blobs, column: :blob_id
  end

  # Test model tables
  create_table :blog_posts do |t|
    t.string :title
    t.string :external_id
    t.string :legacy_id
    t.float :earnings
    t.text :tags
    t.belongs_to :author
  end

  create_table :comments do |t|
    t.string :txt
    t.belongs_to :blog_post
  end

  create_table :authors do |t|
    t.string :name
    t.string :external_id
  end
end

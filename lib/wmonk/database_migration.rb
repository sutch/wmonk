require 'active_record'

module Wmonk

  class DatabaseMigration < ActiveRecord::Migration
    def up

      self.verbose = false

      create_table :urls do |t|
        t.text :value, null: false
      end
      add_index :urls, [:value], unique: true

      create_table :exchanges do |t|  # HTTP exchange
        t.references :url, null: false
        t.string :status_code, null: false
        t.references :content_item
        t.binary :anemone_page, null: false
        t.timestamps
      end
      add_index :exchanges, [:url_id]
      add_index :exchanges, [:content_item_id]

      create_table :content_items do |t|  # message body and content type obtained from one or more responses
        t.references :body, null: false
        t.references :content_type, null: false
        t.binary :is_parsed
      end
      add_index :content_items, [:body_id, :content_type_id], unique: true

      create_table :bodies do |t|  # HTTP response message body
        t.binary :value, null: false
        t.string :digest, null: false
      end
      add_index :bodies, [:value], unique: true
      add_index :bodies, [:digest], unique: true

      create_table :content_types do |t|
        t.string :value
      end
      add_index :content_types, [:value], unique: true

      create_table :links do |t|  # links found within message body of a specific content type
        t.string :value, null: false
        t.references :content_item, null: false
      end
      add_index :links, [:value, :content_item_id], unique: true

    end
  end
end

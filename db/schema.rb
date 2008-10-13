# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081013011427) do

  create_table "articles", :force => true do |t|
    t.text   "content"
    t.string "markup_type", :limit => 100
  end

  create_table "asset_permissions", :force => true do |t|
    t.string  "content_type"
    t.integer "create_permission",         :limit => 8
    t.integer "default_read_permission",   :limit => 8
    t.integer "default_update_permission", :limit => 8
    t.integer "default_delete_permission", :limit => 8
  end

  create_table "asset_statuses", :force => true do |t|
    t.string  "name",        :limit => 50
    t.integer "description"
  end

  create_table "asset_views", :force => true do |t|
    t.integer  "asset_id"
    t.integer  "user_id"
    t.string   "ip_address",     :limit => 50
    t.string   "user_agent"
    t.datetime "created_at"
    t.integer  "publication_id"
    t.string   "referrer"
    t.string   "format",         :limit => 5
  end

  create_table "assets", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.text     "description"
    t.integer  "created_by"
    t.datetime "created_at"
    t.integer  "updated_by"
    t.datetime "updated_at"
    t.integer  "view_count",                           :default => 0
    t.integer  "status"
    t.integer  "content_rating",                       :default => 5
    t.string   "sublocation"
    t.string   "location"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "language",               :limit => 20
    t.float    "altitude"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "geocode_accuracy"
    t.integer  "geocode_method",                       :default => 0
    t.integer  "allow_comments"
    t.boolean  "moderate_comments"
    t.integer  "content_id"
    t.string   "content_type"
    t.datetime "dont_publish_before"
    t.datetime "dont_publish_after"
    t.integer  "read_permissions",       :limit => 8
    t.integer  "update_permissions",     :limit => 8
    t.integer  "delete_permissions",     :limit => 8
    t.integer  "publications",           :limit => 8
    t.boolean  "comments_require_login",               :default => false, :null => false
    t.string   "copyright_notice"
    t.boolean  "include_in_index",                     :default => true
    t.boolean  "allow_pingbacks",                      :default => true,  :null => false
    t.integer  "map_zoom_level",         :limit => 2,  :default => 4
  end

  add_index "assets", ["name", "content_type"], :name => "index_on_name_and_content_type", :unique => true

  create_table "assets_categories", :id => false, :force => true do |t|
    t.integer "asset_id"
    t.integer "category_id"
  end

  add_index "assets_categories", ["asset_id", "category_id"], :name => "asset_id", :unique => true
  add_index "assets_categories", ["asset_id", "category_id"], :name => "asset_category_key", :unique => true

  create_table "bookmarks", :force => true do |t|
    t.string  "url"
    t.boolean "ignore_url_errors",               :default => false
    t.string  "http_response_code", :limit => 3
  end

  create_table "catalogs", :force => true do |t|
    t.string  "catalog_type",            :default => "Image"
    t.string  "source"
    t.string  "directory"
    t.string  "link_as"
    t.integer "max_image_dimension",     :default => 800
    t.integer "max_thumbnail_dimension", :default => 160
    t.integer "max_slide_dimension"
    t.integer "max_display_dimension"
    t.string  "upload_directory"
  end

  add_index "catalogs", ["directory"], :name => "index_catalogs_on_directory", :unique => true

  create_table "categories", :force => true do |t|
    t.string "name"
  end

  add_index "categories", ["name"], :name => "name", :unique => true

  create_table "comments", :force => true do |t|
    t.integer  "asset_id"
    t.text     "content"
    t.integer  "created_by"
    t.string   "created_by_email"
    t.string   "created_by_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.boolean  "spam"
    t.float    "spaminess"
    t.string   "signature"
    t.string   "website"
    t.string   "ip_address",       :limit => 20
    t.string   "comment_type",     :limit => 10
  end

  create_table "content_ratings", :force => true do |t|
    t.integer "rating"
    t.string  "name",           :limit => 20
    t.string  "description"
    t.boolean "default_rating"
  end

  create_table "countries", :force => true do |t|
    t.string "name", :limit => 100
  end

  add_index "countries", ["name"], :name => "name", :unique => true

  create_table "country_alternates", :force => true do |t|
    t.string  "alternate_name", :default => "", :null => false
    t.integer "country_id",                     :null => false
  end

  add_index "country_alternates", ["alternate_name"], :name => "index_alternate_country_name", :unique => true
  add_index "country_alternates", ["country_id"], :name => "index_country_id"

  create_table "galleries", :force => true do |t|
    t.string "gallery_of"
  end

  create_table "images", :force => true do |t|
    t.string   "filename"
    t.string   "folder"
    t.integer  "width"
    t.integer  "height"
    t.string   "owner",                 :limit => 25
    t.datetime "taken_at"
    t.string   "scene"
    t.string   "subjects"
    t.string   "genre"
    t.string   "photographer"
    t.string   "iso",                   :limit => 5
    t.string   "aperture",              :limit => 5
    t.string   "shutter",               :limit => 8
    t.string   "camera_make",           :limit => 20
    t.string   "camera_model",          :limit => 20
    t.string   "camera_owner",          :limit => 20
    t.string   "camera_serial_number",  :limit => 15
    t.string   "exposure_compensation", :limit => 10
    t.string   "flash_compensation",    :limit => 10
    t.string   "lens",                  :limit => 20
    t.string   "focus_point",           :limit => 10
    t.string   "focus_mode",            :limit => 10
    t.string   "drive_mode",            :limit => 10
    t.string   "subject_distance",      :limit => 5
    t.string   "self_timer",            :limit => 5
    t.string   "focal_length",          :limit => 15
    t.string   "metering_mode",         :limit => 15
    t.string   "exposure_mode",         :limit => 15
    t.string   "flash",                 :limit => 10
    t.string   "white_balance",         :limit => 10
    t.string   "orientation",           :limit => 1
    t.integer  "catalog_id"
  end

  add_index "images", ["filename"], :name => "index_images_on_filename", :unique => true
  add_index "images", ["taken_at"], :name => "index_images_on_taken_at"
  add_index "images", ["photographer"], :name => "index_images_on_photographer"
  add_index "images", ["folder"], :name => "index_images_on_folder"

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.text     "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "maps", :force => true do |t|
    t.float   "latitude_center"
    t.float   "longitude_center"
    t.integer "zoom"
    t.integer "map_type"
    t.integer "object_id"
    t.string  "object_type"
    t.string  "track_filename"
    t.text    "javascript"
  end

  create_table "messages", :force => true do |t|
    t.string   "created_by_name",  :limit => 50
    t.string   "created_by_email", :limit => 50
    t.string   "website"
    t.text     "content"
    t.integer  "created_by"
    t.string   "ip_address",       :limit => 20
    t.string   "browser"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.binary  "server_url"
    t.string  "handle"
    t.binary  "secret"
    t.integer "issued"
    t.integer "lifetime"
    t.string  "assoc_type"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.string  "nonce"
    t.integer "created"
  end

  create_table "open_id_authentication_settings", :force => true do |t|
    t.string "setting"
    t.binary "value"
  end

  create_table "pages", :force => true do |t|
    t.integer  "article_id"
    t.string   "name"
    t.integer  "position"
    t.string   "heading"
    t.text     "content"
    t.string   "markup",     :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paper_sizes", :force => true do |t|
    t.integer "short_side_imperial"
    t.integer "short_side_metric"
  end

  add_index "paper_sizes", ["short_side_metric"], :name => "key_metric_size", :unique => true

  create_table "pingbacks", :force => true do |t|
    t.string   "target_uri"
    t.string   "source_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pingbacks", ["target_uri", "source_uri"], :name => "index_pingbacks_on_target_uri_and_source_uri", :unique => true

  create_table "publication_assets", :force => true do |t|
    t.integer "publication_id"
    t.integer "article_id"
  end

  add_index "publication_assets", ["publication_id", "article_id"], :name => "index_publication_articles_on_publication_id_and_article_id"

  create_table "publications", :force => true do |t|
    t.integer "bit_id",                     :limit => 8
    t.string  "theme"
    t.string  "domain"
    t.integer "articles_per_page",                         :default => 10
    t.integer "comments_disabled_after",                   :default => 0
    t.boolean "default_publication",                       :default => false
    t.integer "publish_status",                            :default => 1
    t.text    "publish_status_description"
    t.string  "pop_server"
    t.integer "port_number",                               :default => 110
    t.string  "email_userid"
    t.string  "email_password"
    t.string  "admin_email"
    t.string  "google_analytics"
    t.string  "google_maps"
    t.string  "defensio_api_key",           :limit => 100
  end

  create_table "related_assets", :force => true do |t|
    t.integer "article_id"
    t.integer "related_article_id"
    t.string  "title"
    t.string  "url"
  end

  create_table "slides", :force => true do |t|
    t.integer "gallery_id"
    t.integer "image_id"
    t.integer "position"
  end

  add_index "slides", ["gallery_id", "image_id"], :name => "index_slides_on_gallery_id_and_image_id", :unique => true

  create_table "synonyms", :force => true do |t|
    t.string "name"
    t.string "synonym"
  end

  add_index "synonyms", ["name", "synonym"], :name => "index_synonyms_on_category_and_synonym", :unique => true
  add_index "synonyms", ["name"], :name => "index_synonyms_on_category"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string  "name",      :limit => 50
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
  end

  add_index "tags", ["name"], :name => "index_categories_on_name"

  create_table "unknown_tags", :force => true do |t|
    t.integer "position"
    t.string  "name"
    t.integer "tag_count",    :default => 0
    t.string  "add_to"
    t.string  "synonym_of"
    t.text    "found_in"
    t.string  "updated_with"
  end

  create_table "users", :force => true do |t|
    t.integer  "groups",                    :limit => 8,   :default => 0,     :null => false
    t.string   "nick_name"
    t.string   "login"
    t.string   "given_name"
    t.string   "family_name"
    t.string   "email"
    t.date     "birthday"
    t.text     "profile"
    t.integer  "show_profile",              :limit => 1
    t.string   "display_theme"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.integer  "photo"
    t.integer  "show_photo",                :limit => 1
    t.boolean  "disabled",                                 :default => false
    t.string   "time_zone",                 :limit => 100
    t.string   "locale",                    :limit => 20
    t.string   "identity_url"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code"
    t.datetime "activated_at"
    t.string   "website"
  end

  add_index "users", ["email"], :name => "index_authors_on_email", :unique => true

end

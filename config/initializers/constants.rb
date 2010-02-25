# Accuracy returned by Google when geocoding an asset
# Indexed into this array
Google_geocode_accuracy = [
  "Unknown",
  "Country",
  "Region",
  "Sub-region",
  "Town",
  "Postcode",
  "Street",
  "Intersection",
  "Address",
  "Premise"
  ]
  
GOOGLE_MAPS                       = YAML::load_file("#{RAILS_ROOT}/config/gmaps_api_config.yml")["#{RAILS_ENV}"].symbolize_keys

# User agent for image uploader
HERMES_IMAGE_UPLOADER_USER_AGENT  = "Hermes-ImageUploader/1.0"
HERMES_UPLOAD                     = YAML::load_file("#{RAILS_ROOT}/config/hermes_upload.yml")["#{RAILS_ENV}"].symbolize_keys
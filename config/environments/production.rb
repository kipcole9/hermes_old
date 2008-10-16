# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
MAILER_CREDENTIALS = YAML::load_file("#{RAILS_ROOT}/config/mailer_credentials.yml")["#{RAILS_ENV}"].symbolize_keys
config.action_mailer.raise_delivery_errors          = true
config.action_mailer.perform_deliveries             = true
config.action_mailer.delivery_method                :smtp
config.action_mailer.smtp_settings = {
  :address        => 'smtp.bizmail.yahoo.com',
  :port           => 25,
  :domain         => 'bizmail.yahoo.com',
  :authentication => :login,
  :user_name      => MAILER_CREDENTIALS[:user],
  :password       => MAILER_CREDENTIALS[:password]
}


# Disable raising errors when mass-assigning to a protected attribute
# config.active_record.whiny_protected_attributes = false

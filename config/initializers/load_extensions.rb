# Include extensions
Dir.glob("#{RAILS_ROOT}/lib/hermes/**/*.rb").each do |f|
  require f
end




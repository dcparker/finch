Merb.logger.info("Loaded PRODUCTION Environment...")
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes] = false
  c[:log_level] = :error
  c[:log_file] = Merb.log_path + "/production.log"
}


Merb::BootLoader.after_app_loads do
  warn "Production database not set up. Please edit config/environments/production.rb!"
  # DataMapper.setup(:default, 'sqlite3:config/development.sqlite3')
end

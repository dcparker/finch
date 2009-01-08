Merb.logger.info("Loaded DEVELOPMENT Environment...")
Merb::Config.use { |c|
  c[:exception_details] = true
  c[:reload_classes] = true
  c[:reload_time] = 0.5
  c[:log_auto_flush ] = true
  c[:ignore_tampered_cookies] = true
  c[:log_level] = :debug
}
Merb::BootLoader.after_app_loads do
  DataMapper.setup(:default, 'sqlite3:test/development.sqlite3')
  DataMapper.auto_migrate! unless File.exists?('test/development.sqlite3')
end

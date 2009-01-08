Merb.logger.info("Loaded TEST Environment...")
Merb::Config.use { |c|
  c[:testing] = true
  c[:exception_details] = true
  c[:log_auto_flush ] = true
}

Merb::BootLoader.after_app_loads do
  # Should really use sqlite3 in-memory.
  DataMapper.setup(:default, 'sqlite3:test/test.sqlite3')
end

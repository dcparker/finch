# Go to http://wiki.merbivore.com/pages/init-rb
 
require File.dirname(__FILE__) + "/rubundler"
r = Rubundler.new
r.setup_env
r.setup_requirements

use_orm :datamapper
use_test :rspec
use_template_engine :haml

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = '0106c478e6efcda7d08d745e58513cf29638414c'  # required for cookie session store
  c[:session_id_key] = '_finch_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
  require 'lib/time_point'
  require 'lib/dm-time_point'
  require 'lib/dm-money'
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  DataMapper.auto_upgrade!
end

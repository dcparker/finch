Gem.clear_paths
Gem.path.unshift(Merb.root / "gems")
Merb.push_path(:lib, Merb.root / "lib")



# ==== Set up your basic configuration ===
Merb::Config.use do |c|
  c[:session_id_key] = '_finch_session_id'
  c[:session_secret_key]  = '3235f84b849d09e29b1dcbe5f8cd9c9355573a3e'
  c[:session_store] = 'cookie'
end



# ==== Set up your ORM of choice ===
use_orm :datamapper
# ==== Pick what you test with ===
use_test :rspec
# ==== Choose default template engine ===
use_template_engine :haml
# use_template_engine :erb



# ==== Dependencies ===
require 'lib/merb-park'
require 'merb-slices'
require 'merb-auth'

Merb::BootLoader.before_app_loads do
  Merb::Slices.config[:merb_auth] = { :layout => :application }
end

Merb::BootLoader.after_app_loads do
  MA[:use_activation] = false #=> Uses activation emails to confirm user is human.
  MA[:forgotten_password] = true #=> Enables forgotten password usage.
  MA[:route_path_model] ||= :users
  MA[:route_path_session] ||= :sessions
end

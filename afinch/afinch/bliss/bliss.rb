# Require the APP config
$LOAD_PATH.unshift(Merb.root / "bliss")
require File.join(Merb.root, 'config', 'app_config.rb')

# All the standard gems
dependency 'mailfactory'
dependency 'oauth'
dependency 'ruby-openid'
require 'bliss_magic'
require 'global_helpers'
require 'days_and_times'

require 'dm_extensions'
require 'optional_and_private_properties'
require 'is_searchable'
require 'orm_authorization'
require 'external_ids'

require 'tracks_deleted'
require 'router_helper'
class Application < Merb::Controller
  include GlobalHelpers
end
require 'pathway' # Has to be after GlobalHelpers is loaded

Merb::BootLoader.after_app_loads do
  require 'presenter' # Has to after Application is loaded
  require 'signin_controller' # Has to be after Pathway and Presenter are loaded
  Application.send :include, SigninController # Has to be after Application is loaded
  require 'blissful_openid' # Has to be after Application is loaded
  require 'blissful_oauth' # Has to be after Application is loaded
end

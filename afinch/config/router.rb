Merb.logger.info("Compiling routes...")
Merb::Router.prepare do |r|
  r.add_slice(:MerbAuth, :path => "", :default_routes => false)

  r.match('/').to(:controller => 'xions', :action => 'index')
  r.resources :xions
end

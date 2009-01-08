Gem::Specification.new do |s|
  s.name = %q{merb-auth}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Merb Core"]
  s.date = %q{2008-09-17}
  s.description = %q{Merb Slice that provides authentication}
  s.email = %q{has.sox@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/merb-auth", "lib/merb-auth/adapters", "lib/merb-auth/adapters/activerecord", "lib/merb-auth/adapters/activerecord/init.rb", "lib/merb-auth/adapters/activerecord/map.rb", "lib/merb-auth/adapters/activerecord/model.rb", "lib/merb-auth/adapters/common.rb", "lib/merb-auth/adapters/datamapper", "lib/merb-auth/adapters/datamapper/init.rb", "lib/merb-auth/adapters/datamapper/map.rb", "lib/merb-auth/adapters/datamapper/model.rb", "lib/merb-auth/adapters/map.rb", "lib/merb-auth/controller", "lib/merb-auth/controller/controller.rb", "lib/merb-auth/controller/sessions_base.rb", "lib/merb-auth/controller/users_base.rb", "lib/merb-auth/initializer.rb", "lib/merb-auth/merbtasks.rb", "lib/merb-auth/slicetasks.rb", "lib/merb-auth.rb", "spec/controllers", "spec/controllers/plugins", "spec/controllers/plugins/test_plugin.rb", "spec/controllers/sessions_spec.rb", "spec/controllers/users_spec.rb", "spec/mailers", "spec/mailers/user_mailer_spec.rb", "spec/merb_auth_spec.rb", "spec/models", "spec/models/ar_model_spec.rb", "spec/models/common_spec.rb", "spec/models/model_spec.rb", "spec/shared_specs", "spec/shared_specs/shared_model_spec.rb", "spec/spec_helper.rb", "spec/spec_helpers", "spec/spec_helpers/helpers.rb", "spec/spec_helpers/valid_model_hashes.rb", "app/controllers", "app/controllers/application.rb", "app/controllers/sessions.rb", "app/controllers/users.rb", "app/helpers", "app/helpers/application_helper.rb", "app/mailers", "app/mailers/user_mailer.rb", "app/mailers/views", "app/mailers/views/user_mailer", "app/mailers/views/user_mailer/activation.text.erb", "app/mailers/views/user_mailer/forgot_password.text.erb", "app/mailers/views/user_mailer/signup.text.erb", "app/views", "app/views/layout", "app/views/layout/merb_auth.html.erb", "app/views/sessions", "app/views/sessions/new.html.erb", "app/views/users", "app/views/users/new.html.erb", "public/javascripts", "public/javascripts/master.js", "public/stylesheets", "public/stylesheets/master.css", "stubs/app", "stubs/app/controllers", "stubs/app/controllers/application.rb", "stubs/app/controllers/main.rb", "stubs/app/mailers", "stubs/app/mailers/views", "stubs/app/mailers/views/activation.text.erb", "stubs/app/mailers/views/signup.text.erb", "stubs/app/views", "stubs/app/views/sessions", "stubs/app/views/sessions/new.html.erb", "stubs/app/views/users", "stubs/app/views/users/new.html.erb", "activerecord_generators/ma_migration", "activerecord_generators/ma_migration/ma_migration_generator.rb", "activerecord_generators/ma_migration/templates", "activerecord_generators/ma_migration/templates/schema", "activerecord_generators/ma_migration/templates/schema/migrations", "activerecord_generators/ma_migration/templates/schema/migrations/%time_stamp%_add_ma_user.rb", "datamapper_generators/ma_migration", "datamapper_generators/ma_migration/ma_migration_generator.rb", "datamapper_generators/ma_migration/templates", "datamapper_generators/ma_migration/templates/schema", "datamapper_generators/ma_migration/templates/schema/migrations", "datamapper_generators/ma_migration/templates/schema/migrations/add_ma_user.rb", "plugins/forgotten_password", "plugins/forgotten_password/app", "plugins/forgotten_password/app/controllers", "plugins/forgotten_password/app/controllers/passwords.rb", "plugins/forgotten_password/app/models", "plugins/forgotten_password/app/models/user.rb", "plugins/forgotten_password/app/views", "plugins/forgotten_password/app/views/passwords", "plugins/forgotten_password/app/views/passwords/edit.html.erb", "plugins/forgotten_password/app/views/passwords/new.html.erb", "plugins/forgotten_password/forgotten_password.rb", "plugins/forgotten_password/init.rb", "plugins/forgotten_password/spec", "plugins/forgotten_password/spec/controller_spec.rb", "plugins/forgotten_password/spec/model_spec.rb", "plugins/forgotten_password/spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://merbivore.com/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Merb Slice that provides authentication}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<merb-slices>, [">= 0.9.4"])
      s.add_runtime_dependency(%q<merb-mailer>, [">= 0.9.4"])
      s.add_runtime_dependency(%q<merb_helpers>, [">= 0.9.4"])
    else
      s.add_dependency(%q<merb-slices>, [">= 0.9.4"])
      s.add_dependency(%q<merb-mailer>, [">= 0.9.4"])
      s.add_dependency(%q<merb_helpers>, [">= 0.9.4"])
    end
  else
    s.add_dependency(%q<merb-slices>, [">= 0.9.4"])
    s.add_dependency(%q<merb-mailer>, [">= 0.9.4"])
    s.add_dependency(%q<merb_helpers>, [">= 0.9.4"])
  end
end

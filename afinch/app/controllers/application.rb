class Application < Merb::Controller
  include MerbPark::Controller
  before :login_required
end

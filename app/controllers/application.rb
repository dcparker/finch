class Application < Merb::Controller
  def my(association_method)
    session.user.send(association_method)
  end
end

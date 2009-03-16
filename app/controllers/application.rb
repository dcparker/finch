class Application < Merb::Controller
  def my(association_method)
    session.user.send(association_method)
  end

  def auto_login
    session[:user] = User.first.id
  end
end

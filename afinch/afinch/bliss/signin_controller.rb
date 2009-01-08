require 'openid_url'

class Login
  class << self
    # For those apps who don't have a database
    def first(properties={})
      properties[:openid_url]
    end unless method_defined?(:first)
    def create(properties={})
      properties[:openid_url]
    end unless method_defined?(:create)
  end
end
class Person
  def self.current
    p = Thread.current['current_person']
    p.static(:guid => p) unless p.respond_to?(:guid)
    p
  end
  def self.current_guid
    self.current ? self.current.guid : nil
  end
  def self.first(properties={})
    properties[:openid_url]
  end unless method_defined?(:first)
end

module SigninController
  def self.included(base)
    def base.current_person=(guid)
      return nil if guid.blank?
      without_orm_authorization do
        Thread.current['current_person'] = Person.first(:openid_url => OpenIDUrl.new(guid).normalized)
      end
    end
    def base.current_person
      Thread.current['current_person']
    end
    def base.signed_in?
      !!current_person
    end
  end

  def current_person(reload=false)
    if reload || !@current_person
      # First, attempt to recognize the user by OAuth login
      self.class.current_person ||= oauth_instance.person.guid if is_oauth? && oauth_instance.person
      # Second, attempt to authenticate by session (cookies)
      self.class.current_person ||= session[:openid_url]
      @current_person = self.class.current_person
    end
    @current_person
  end
  def current_person=(openid_url)
    self.class.current_person = session[:openid_url] = openid_url
  end
  def signout!
    session.data.delete(:openid_url)
    Thread.current['current_person'] = nil
    true
  end

  def signed_in?
    !!current_person
  end
end

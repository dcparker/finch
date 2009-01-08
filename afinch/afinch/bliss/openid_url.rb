class OpenIDUrl
  def initialize(openid_url)
    @raw = openid_url.to_s
  end

  delegate_methods [:host] => :uri

  def normalized
    normalize rescue nil
  end
  def normalize
    begin
      @normalized ||= OpenID.normalize_url(@raw)
    rescue
      raise TypeError, "#{@raw} is not a valid openid_url"
    end
  end

  def valid?
    !!normalized rescue false
  end
  alias :is_openid? :valid?

  # Compares the OpenIDUrl object with either another OpenIDUrl object, or simply a String
  def ==(other)
    case other
    when String
      self.normalized == OpenIDUrl.new(other).normalized rescue false
    when OpenIDUrl
      self.normalized == other.normalized
    else
      raise TypeError, "cannot compare OpenIDUrl to #{other.class}"
    end
  end

  # Returns a URI object wrapped around the normalized openid_url.
  def uri
    URI.parse(normalized) rescue nil
  end
end

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/dash" do
  before(:each) do
    @response = request("/dash")
  end
end
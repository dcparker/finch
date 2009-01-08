require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a envelope exists" do
  Envelope.all.destroy!
  request(resource(:envelopes), :method => "POST", 
    :params => { :envelope => { :id => nil }})
end

describe "resource(:envelopes)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:envelopes))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of envelopes" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a envelope exists" do
    before(:each) do
      @response = request(resource(:envelopes))
    end
    
    it "has a list of envelopes" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Envelope.all.destroy!
      @response = request(resource(:envelopes), :method => "POST", 
        :params => { :envelope => { :id => nil }})
    end
    
    it "redirects to resource(:envelopes)" do
      @response.should redirect_to(resource(Envelope.first), :message => {:notice => "envelope was successfully created"})
    end
    
  end
end

describe "resource(@envelope)" do 
  describe "a successful DELETE", :given => "a envelope exists" do
     before(:each) do
       @response = request(resource(Envelope.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:envelopes))
     end

   end
end

describe "resource(:envelopes, :new)" do
  before(:each) do
    @response = request(resource(:envelopes, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@envelope, :edit)", :given => "a envelope exists" do
  before(:each) do
    @response = request(resource(Envelope.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@envelope)", :given => "a envelope exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Envelope.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @envelope = Envelope.first
      @response = request(resource(@envelope), :method => "PUT", 
        :params => { :envelope => {:id => @envelope.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@envelope))
    end
  end
  
end


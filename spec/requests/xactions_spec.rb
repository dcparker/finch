require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a xaction exists" do
  Xaction.all.destroy!
  request(resource(:xactions), :method => "POST", 
    :params => { :xaction => { :id => nil }})
end

describe "resource(:xactions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:xactions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of xactions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a xaction exists" do
    before(:each) do
      @response = request(resource(:xactions))
    end
    
    it "has a list of xactions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Xaction.all.destroy!
      @response = request(resource(:xactions), :method => "POST", 
        :params => { :xaction => { :id => nil }})
    end
    
    it "redirects to resource(:xactions)" do
      @response.should redirect_to(resource(Xaction.first), :message => {:notice => "xaction was successfully created"})
    end
    
  end
end

describe "resource(@xaction)" do 
  describe "a successful DELETE", :given => "a xaction exists" do
     before(:each) do
       @response = request(resource(Xaction.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:xactions))
     end

   end
end

describe "resource(:xactions, :new)" do
  before(:each) do
    @response = request(resource(:xactions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@xaction, :edit)", :given => "a xaction exists" do
  before(:each) do
    @response = request(resource(Xaction.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@xaction)", :given => "a xaction exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Xaction.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @xaction = Xaction.first
      @response = request(resource(@xaction), :method => "PUT", 
        :params => { :xaction => {:id => @xaction.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@xaction))
    end
  end
  
end


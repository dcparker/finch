require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a schedule exists" do
  Schedule.all.destroy!
  request(resource(:schedules), :method => "POST", 
    :params => { :schedule => { :id => nil }})
end

describe "resource(:schedules)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:schedules))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of schedules" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a schedule exists" do
    before(:each) do
      @response = request(resource(:schedules))
    end
    
    it "has a list of schedules" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Schedule.all.destroy!
      @response = request(resource(:schedules), :method => "POST", 
        :params => { :schedule => { :id => nil }})
    end
    
    it "redirects to resource(:schedules)" do
      @response.should redirect_to(resource(Schedule.first), :message => {:notice => "schedule was successfully created"})
    end
    
  end
end

describe "resource(@schedule)" do 
  describe "a successful DELETE", :given => "a schedule exists" do
     before(:each) do
       @response = request(resource(Schedule.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:schedules))
     end

   end
end

describe "resource(:schedules, :new)" do
  before(:each) do
    @response = request(resource(:schedules, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@schedule, :edit)", :given => "a schedule exists" do
  before(:each) do
    @response = request(resource(Schedule.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@schedule)", :given => "a schedule exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Schedule.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @schedule = Schedule.first
      @response = request(resource(@schedule), :method => "PUT", 
        :params => { :schedule => {:id => @schedule.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@schedule))
    end
  end
  
end


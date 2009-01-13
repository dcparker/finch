require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a budget exists" do
  Budget.all.destroy!
  request(resource(:budgets), :method => "POST", 
    :params => { :budget => { :id => nil }})
end

describe "resource(:budgets)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:budgets))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of budgets" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a budget exists" do
    before(:each) do
      @response = request(resource(:budgets))
    end
    
    it "has a list of budgets" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Budget.all.destroy!
      @response = request(resource(:budgets), :method => "POST", 
        :params => { :budget => { :id => nil }})
    end
    
    it "redirects to resource(:budgets)" do
      @response.should redirect_to(resource(Budget.first), :message => {:notice => "budget was successfully created"})
    end
    
  end
end

describe "resource(@budget)" do 
  describe "a successful DELETE", :given => "a budget exists" do
     before(:each) do
       @response = request(resource(Budget.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:budgets))
     end

   end
end

describe "resource(:budgets, :new)" do
  before(:each) do
    @response = request(resource(:budgets, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@budget, :edit)", :given => "a budget exists" do
  before(:each) do
    @response = request(resource(Budget.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@budget)", :given => "a budget exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Budget.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @budget = Budget.first
      @response = request(resource(@budget), :method => "PUT", 
        :params => { :budget => {:id => @budget.id} })
    end
  
    it "redirect to the article show action" do
      @response.should redirect_to(resource(@budget))
    end
  end
  
end


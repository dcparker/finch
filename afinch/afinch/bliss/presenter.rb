class Presenter < Application
  extend Forwardable
  
  def initialize(controller,params={})
    @controller = controller
    params.each_pair do |attribute, value| 
      self.send :"#{attribute}=", value
    end
  end

  def view?
    @controller.instance_variables.include?('@_view_context_cache')
  end

  def info?
    !info.blank?
  end
  def info(msg=nil)
    @controller.session[:presenter] ||= {}
    @info ||= []
    @controller.session[:presenter].delete(:info) if @info.blank?
    @controller.session[:presenter][:info] ||= []
    if msg
      @info << msg
      @controller.session[:presenter][:info] << msg
    else
      @controller.session[:presenter][:info]
    end
  end
  def instruct?
    !instruct.blank?
  end
  def instruct(msg=nil)
    @controller.session[:presenter] ||= {}
    @instruct ||= []
    @controller.session[:presenter].delete(:instruct) if @instruct.blank?
    @controller.session[:presenter][:instruct] ||= []
    if msg
      @instruct << msg
      @controller.session[:presenter][:instruct] << msg
    else
      @controller.session[:presenter][:instruct]
    end
  end
  def error?
    !error.blank?
  end
  def error(msg=nil)
    @controller.session[:presenter] ||= {}
    @error ||= []
    @controller.session[:presenter].delete(:error) if @error.blank?
    @controller.session[:presenter][:error] ||= []
    if msg
      @error << msg
      @controller.session[:presenter][:error] << msg
    else
      @controller.session[:presenter][:error]
    end
  end

  def no_display!
    @no_display = true
  end
  def display?
    !@no_display
  end
end

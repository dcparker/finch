module GlobalHelpers
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
  end

  private
    def presenter
      @presenter ||= Presenter.new(self)
    end

    # This is error-prone with faulty configuration: APP[:default_openid] MUST be set to a Proc!
    def nickname_from_identity_url(login)
      nickname = login.to_s.match(/([^\/]+)$/)[1]
      return nickname if login == nickname || OpenIDUrl.new(login).is_openid?
      return nickname if OpenIDUrl.new(login) == APP[:default_openid].call(nickname)
      return login
    end

    def captcha
      if presenter.view?
        # In the view: Create and render a captcha
      else
        # In the controller: Validate the captcha, return true or false
        # presenter.error "Your Captcha validation wasn't valid. Please enter the letters and numbers you see in the picture."
        true
      end
    end

    def render_partial_as_dialog(*args,&blk)
      opts = (Hash === args.last) ? args.pop : {}
      args = args.push(opts.merge(:layout => :none, :format => :html))

      res = ["$('#ex3a').remove();\n",
        "$('body').append('",
      escape_js(<<-dialog_html
      <div id="ex3a" class="jqmDialog">
      <div class="jqmdTL"><div class="jqmdTR"><div class="jqmdTC jqDrag">#{opts[:title]}</div></div></div>
      <div class="jqmdBL"><div class="jqmdBR"><div class="jqmdBC">

      <div class="jqmdMSG">
      #{render(*args, &blk)}
      </div>

      </div></div></div>
      <input type="image" src="dialog/close.gif" class="jqmdX jqmClose" />
      </div>
  dialog_html
      ),
      "');",
      <<-dialog_script
      $('#ex3a form').ajaxForm();
      $('#ex3a').jqm({
        overlay: 75,
        overlayClass: 'jqmOverlay'})
      .jqDrag('.jqDrag');
      $('input.jqmdX')
      .hover(
        function(){ $(this).addClass('jqmdXFocus'); }, 
        function(){ $(this).removeClass('jqmdXFocus'); })
      .focus( 
        function(){ this.hideFocus=true; $(this).addClass('jqmdXFocus'); })
      .blur( 
        function(){ $(this).removeClass('jqmdXFocus'); });
      $('#ex3a').jqmShow();
  dialog_script
      ].join
      # ^^ Script to change the action on any forms included, to ajax-submit instead
      set_response_headers :js
      res
    end

    def url_for(action_or_object, object=nil)
      if action_or_object.is_a?(Symbol)
        action = action_or_object
        raise ArgumentError, "must include an object when calling a url_for with a singular symbol as the first argument" if action.to_s.pluralize != action.to_s && object.nil?
      else
        object = action_or_object
        raise ArgumentError, "must include either an object or an action, or both" if object.nil?
        action = :show # If none was specified, assume show
      end
      if object.is_a?(Class)
        object_class = object.name.underscore
      else
        object_class = object.class.name.underscore
      end
      counter_actions = { # The action will be swapped if the record doesn't exist.
        :new => :new,
        :create => :create,
        :show => :new,
        :edit => :new,
        :update => :create,
        :destroy => :destroy, # Destroy can be called on non-existent records
      }
      named_route = if object.new_record?
        "#{counter_actions[action].to_s}_#{object_class}"
      elsif [:destroy, :show].include?(action)
        object_class
      else
        "#{action.to_s}_#{object_class}"
      end
      action == :destroy ? "javascript:$(body).append('<form style=\"display:none\" id=\"dynamic_form_123987\" action=\"#{url(object_class, object)}\" method=\"POST\"><input type=\"hidden\" name=\"_method\" value=\"DELETE\" /></form>'); $('#dynamic_form_123987').submit();" : url(named_route.to_sym, object)
    end

    def escape_js(javascript)
      (javascript || '').gsub('\\','\0\0').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
    end

    def valid_params(name='')
      name = name.to_s
      if presenter.view?
        session['valid_params-'+name] = String.random(24)
      else
        session['valid_params-'+name] == params['valid_params']
      end
    end
end

module Merb
  # Adds a method 'abs_url' the GeneralControllerMixin 
  module GeneralControllerMixin
    def abs_url(*args)
      APP[:web_root] + url(*args)
    end
  end
end

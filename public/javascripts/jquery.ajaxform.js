(function($){
  $.fn.ajaxForm = function(options){
    if(!options)var options={};
    $(this).submit(function(){
      options.form = this;
      options.url = this.action;
      options.type = this.method;
      options.data = $(this).serialize();
      $.ajax(options);
      return false;
    });
  };

  $.fn.ajaxSubmit = function(options){
    if(!options)var options={};
    $(this).each(function(){
      options.form = this;
      options.url = this.action;
      options.type = this.method;
      options.data = $(this).serialize();
      $.ajax(options);
    });
  };
})(jQuery);

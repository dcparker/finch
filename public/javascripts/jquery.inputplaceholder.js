$(function(){
  $('input').each(function(){
    var input=$(this);
    var title=input.attr('title');
    if(title){
      delete this.title;
      var erase;
      var set = function(e){
        if(input.val()==''){
          input.val(title);
          input.css('color', '#999');
        }
        input.focus(erase);
      };
      erase = function(e){
        if(input.val()==title)input.val('');
        input.css('color', '#000');
        input.unbind('focus', erase);
        input.blur(set);
      };
      set();
    }
  });
});

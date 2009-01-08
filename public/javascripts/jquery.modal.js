var App = new Object;
App.Modal = new Object;
App.Modal.make = function(html){
  App.Modal.create(html);
  App.Modal.show();
};
App.Modal.create = function(html){
  $('#modal').remove();
  $('#overlay_container').remove();
  $(html).appendTo($('body'));
};
App.Modal.show = function(){
  $('#overlay_container').addClass('show');
  $('#modal_overlay').click(App.Modal.hide);
  $('#modal').fadeIn('slow').addClass('show').keypress(App.Model.keypress);
};
App.Modal.hide = function(){
  $('#overlay_container').fadeOut('slow',function(){$(this).removeClass('show')});
  $('#modal').fadeOut('normal',function(){$(this).removeClass('show')});
};
App.Modal.keypress = function(e){
  if(e.which==27)App.Modal.hide();
};

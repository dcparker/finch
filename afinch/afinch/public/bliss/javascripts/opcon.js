function blowUpBig(id){
  $("<span id='on_screen_display'>"+$('#'+id).html()+"</span>").displayBox({width : '100%', height : '100%'});
}

$(document).ready(function() {
  $("#search_input").typeWatch({callback:function(e){
    // use the .ajaxSubmit magic with the update option
    $('#search_form').ajaxSubmit({target : '#content'});
  }});
 
  if($("#content form input[type=text]")[0]){
    $("#content form input[type=text]")[0].select();
  } else {
    $("form input[type=text]")[0].select();
  }

	$(".listing").hover(function(){$(this).find('.dim').addClass("show"); $(this).find('input').addClass('show')}, function(){$(this).find('.dim').removeClass("show"); ; $(this).find('input').removeClass('show')})
  	.find('input, select')
  	.bind('focus', function(){$(this).parent('.dim').addClass("show")})
  	.bind('keypress', function(){$(this).parent('.dim').addClass("show")})
  	.bind('blur', function(){$(this).parent('.dim').removeClass("show")});
});

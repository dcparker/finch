// Common JavaScript code across your application goes here.

$(function(){
  $('a, .modal_link').each(function(){
    var a=$(this);
    var href = a.attr('href');
    if(href && href.match(/^\/modal\//) || a.hasClass('modal_link')){
      a.attr('href', "javascript:$('ul.clickmenu').hide()");
      a.click(function(e){
        // e.preventDefault(); // don't prevent default so that the clickmenu will go away.
        $.ajax({url:href,type:'get',data:{layout:'modal'},success:App.Modal.make});
      })
    }
  });

  $('ul.clickmenu').each(function(){
    // Make its parent clickable to show the menu
    var menu=$(this);
    menu.append('<li></li>').append($('<a href="javascript:$(\'ul.clickmenu\').slideUp(\'fast\')">(hide menu)</a>'));
    menu.parent().addClass('clickable').click(function(){
      $('ul.clickmenu').not(menu).slideUp('fast');
      menu.slideDown('fast');
    });
  });

  $('div.envelope div span.X').each(function(){
    var env=$(this);
    var id=env.parents('div.envelope').attr('id').match(/(\d+)/)[1];
    env.mouseover(function(){
      env.css({opacity:1});
    }).mouseout(function(){
      env.css({opacity:.3})
    }).click(function(){
      $.ajax({url:'/envelopes/'+id,type:'post',data:{_method:'DELETE'},success:function(){
        env.parents('div.envelope').remove();
      }});
      return false;
    });
  });
});

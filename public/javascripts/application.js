// Common JavaScript code across your application goes here.

jQuery(function(){var $ = jQuery;

var dragging = null;
drag_options = {
  cursor:'pointer',
  cursorAt:{left:50,top:47},
  helper:function(){return $('img#dollar_sign').clone()},
  revert:true
};
$("#dollar_sign").draggable({
  cursor:'pointer',
  helper:'clone',
  revert: true
});
$(".real_account").draggable(drag_options);
$('.just_envelope').draggable(drag_options);

var view_xactions = function(event, ui) {
  ui.helper.remove();
  var from_id = ui.draggable.get(0).id;
  var to_id = this.id;
  // Open up a dialog asking: amount, description, date, and completed/pending
  $.ajax({url:'/dialogs/view_pending_transactions',type:'get',data:{from_id:to_id,to_id:from_id},success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: { Done:function(){$('#dialog').dialog('close')} }
    });
  }});
};
var new_xaction = function(event, ui) {
  ui.helper.remove();
  var from_id = ui.draggable.get(0).id;
  var to_id = this.id;
  // Open up a dialog asking: amount, description, date, and completed/pending
  $.ajax({url:'/dialogs/new_transaction',type:'get',data:{from_id:from_id,to_id:to_id},success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog .date_picker').datepicker({
      appendText: '(mm/dd/yyyy)',
      dateFormat: 'mm/dd/yy',
      altField: '#transaction_date'
    });
    $('#dialog-form').ajaxForm({
      // Send to the website, wait for the response, then close the dialog and reload the data for the page.
      beforeSend: function(){
        $('img#dollar_sign').clone().appendTo('#dialog ui-dialog-buttonpane');
      },
      success: function(){
        Finch.reloadEnvelopes();
        $('#dialog').dialog('close');
      },
      error: function(xhr){
        $('#dialog-form').append(xhr.responseText);
      }
    });
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: {
        Save:   function(){ $('#dialog-form').submit() },
        Cancel: function(){$('#dialog').dialog('close')}
      }
    });
  }});
};
var new_deposit = function(event, ui) {
  ui.helper.remove();
  var to_id = this.id;
  // Open up a dialog asking: amount, description, date, and completed/pending
  $.ajax({url:'/dialogs/new_transaction',type:'get',data:{to_id:to_id},success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog .date_picker').datepicker({
      appendText: '(mm/dd/yyyy)',
      dateFormat: 'mm/dd/yy',
      altField: '#transaction_date'
    });
    $('#dialog-form').ajaxForm({
      // Send to the website, wait for the response, then close the dialog and reload the data for the page.
      beforeSend: function(){
        $('img#dollar_sign').clone().appendTo('#dialog ui-dialog-buttonpane');
      },
      success: function(){
        Finch.reloadEnvelopes();
        $('#dialog').dialog('close');
      },
      error: function(html){
        alert(html);
      }
    });
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: {
        Save:   function(){ $('#dialog-form').submit() },
        Cancel: function(){$('#dialog').dialog('close')}
      }
    });
  }});
};

$(".envelope").droppable({
  accept: '.envelope, #dollar_sign',
  drop: function(event, ui){
    if(ui.draggable.hasClass('just_envelope')){
      if($(this).hasClass('real_account')){
        view_xactions.apply(this, [event, ui]);
      }else{
        return false;
      }
    }else if(ui.draggable.attr('id') == 'dollar_sign'){
      if($(this).hasClass('real_account')){
        new_deposit.apply(this, [event, ui]);
      }else{
        return false
      }
    }else{
      new_xaction.apply(this, [event, ui]);
    }
  }
});

$(".just_envelope").dblclick(function(){
  var to_id = this.id;
  $.ajax({url:'/dialogs/view_pending_transactions',type:'get',data:{to_id:to_id},success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: { Done:function(){$('#dialog').dialog('close')} }
    });
  }});
});
$(".real_account").dblclick(function(){
  var from_id = this.id;
  $.ajax({url:'/dialogs/view_pending_transactions',type:'get',data:{from_id:from_id},success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: { Done:function(){$('#dialog').dialog('close')} }
    });
  }});
});

$('#new_envelope').click(function(){
  $.ajax({url:'/dialogs/new_envelope',type:'get',success:function(html){
    $('#dialog').remove();
    $(html).appendTo($('body'));
    $('#dialog-form').ajaxForm({
      // Send to the website, wait for the response, then close the dialog and reload the data for the page.
      beforeSend: function(){
        $('img#dollar_sign').clone().appendTo('#dialog ui-dialog-buttonpane');
      },
      success: function(){
        Finch.reloadEnvelopes();
        $('#dialog').dialog('close');
      },
      error: function(html){
        alert(html);
      }
    });
    $('#dialog').dialog({
      modal: true,
      width: 460,
      title: $('#dialog-title').text(),
      close: function(){if(Finch.reload)location.reload()},
      buttons: {
        Create:function(){Finch.reloadEnvelopes();$('#dialog').dialog('close')},
        Cancel:function(){$('#dialog').dialog('close')}
      }
    });
  }});
});

// TODO: The menu and modal links won't be needed anymore once we get the rest of the functions built.
// $('a, .modal_link').each(function(){
//   var a=$(this);
//   var href = a.attr('href');
//   if(href && href.match(/^\/modal\//) || a.hasClass('modal_link')){
//     a.attr('href', "javascript:$('ul.clickmenu').hide()");
//     a.click(function(e){
//       // e.preventDefault(); // don't prevent default so that the clickmenu will go away.
//       $.ajax({url:href,type:'get',data:{layout:'dialog'},success:function(html){
//         $(html).appendTo($('body'));
//         $('#dialog').dialog({
//           modal: true,
//           width: 460
//         });
//       }});
//     })
//   }
// });
// $('ul.clickmenu').each(function(){
//   // Make its parent clickable to show the menu
//   var menu=$(this);
//   menu.append('<li></li>').append($('<a href="javascript:$(\'ul.clickmenu\').slideUp(\'fast\')">(hide menu)</a>'));
//   menu.parent().addClass('clickable').mouseover(function(){
//     $('ul.clickmenu').not(menu).slideUp('fast');
//     menu.slideDown('fast');
//     setTimeout(function(){
//       menu.slideUp();
//     }, 6000)
//   });
// });

});

var Finch = {
  reload:false,
  editXaction:function(xaction_id){
    // Make a form out of it.
    $('#xaction_'+xaction_id+' form').ajaxForm({
      success:function(){
        Finch.reloadEnvelopes();
        $('#xaction_'+xaction_id+' form input[type=text]').each(function(){
          $(this).replaceWith($(this).val());
        });
      }
    });
    $('#xaction_'+xaction_id+' span.editable').each(function(){
      var name = $(this).attr('name');
      $(this).html('<input type="text" name="'+name+'" value="'+$(this).html()+'" size="'+$(this).attr('size')+'" />');
    });
  },
  completeXaction:function(xaction_id){
    $.ajax({url:'/xactions/'+xaction_id,type:'put',data:{'xaction[completed]':true},success:function(html){
      $('#xaction_'+xaction_id).fadeOut('slow',function(){
        $(this).remove();
        Finch.reloadEnvelopes();
        // Close the dialog box if this is the last Xaction.
        if($('#pending_xactions').children().length == 0){
          $('#dialog').dialog('close');
        }
      });
    }});
  },
  reloadEnvelopes:function(){
    if($('#dialog').dialog('isOpen')){
      Finch.reload=true;
    }else{
      // Build a way to reload Envelopes using Ajax
      location.reload();
      // Get json data
      // $.getJSON('/envelopes.json', function(data){
      //   // Insert into all existing envelopes
      //   data.envelopes.each(function(){
      //     CachedUrl.get('/templates/envelope',function(template){
      //       
      //     });
      //   });
      // });
      // * * * *
      Finch.reload=false;
    }
  }
};

var CachedUrl = (function(){
  var cache = {};
  var that = this;
  
  this.get = function(url,callback){
    if(defined(cache[url])){
      callback.call(cache[url]);
    }else{
      $.ajax({url:url,success:function(html){
        cache[url] = html;
        callback.call(html);
      }});
    }
  };
})();

var Template = {
  parse:function(template,data){
    var again = true;
    console.log(pos);
    // while(again){
      var pos = template.indexOf('[[');
      if(pos == -1){
        again = false;
      }else{
        var end_pos = template.indexOf(']]',pos);
        var name = template.substring(pos+2,end_pos);
        template.replace('[['+name+']]',data[name]);
      }
    // }
    return template;
  }
};

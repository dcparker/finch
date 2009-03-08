// Common JavaScript code across your application goes here.

jQuery(function(){var $ = jQuery;
  var dragging = null;
  var drag_options = {
    cursor:'pointer',
    cursorAt:{left:50,top:47},
    helper:function(){return $('img#dollar_sign').clone()},
    revert:true
  };
  $("#dollar_sign").livequery(function(){
    $(this).draggable({
      cursor:'pointer',
      helper:'clone',
      revert: true
    });
  });

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
        close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
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
        close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
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
        close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
        buttons: {
          Save:   function(){ $('#dialog-form').submit() },
          Cancel: function(){$('#dialog').dialog('close')}
        }
      });
    }});
  };

  var make_envelopes_droppable = function(){
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
  };

  $(".just_envelope").livequery(function(){
    $(this).draggable(drag_options);

    $(this).dblclick(function(){
      var to_id = this.id;
      $.ajax({url:'/dialogs/view_pending_transactions',type:'get',data:{to_id:to_id},success:function(html){
        $('#dialog').remove();
        $(html).appendTo($('body'));
        $('#dialog').dialog({
          modal: true,
          width: 460,
          title: $('#dialog-title').text(),
          close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
          buttons: { Done:function(){$('#dialog').dialog('close')} }
        });
      }});
    });

    make_envelopes_droppable();
  });
  $(".real_account").livequery(function(){
    $(this).draggable(drag_options);

    $(this).dblclick(function(){
      var from_id = this.id;
      $.ajax({url:'/dialogs/view_pending_transactions',type:'get',data:{from_id:from_id},success:function(html){
        $('#dialog').remove();
        $(html).appendTo($('body'));
        $('#dialog').dialog({
          modal: true,
          width: 460,
          title: $('#dialog-title').text(),
          close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
          buttons: { Done:function(){$('#dialog').dialog('close')} }
        });
      }});
    });

    make_envelopes_droppable();
  });

  $('#new_envelope').livequery(function(){
    $(this).click(function(){
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
          close: function(){if(Finch.reload)Finch.reloadEnvelopes(true)},
          buttons: {
            Create:function(){Finch.reloadEnvelopes();$('#dialog').dialog('close')},
            Cancel:function(){$('#dialog').dialog('close')}
          }
        });
      }});
    });
  });
});

var CachedUrl = {};
CachedUrl.cache = {};
CachedUrl.get = function(url,callback){
  if(typeof(CachedUrl.cache[url]) != 'undefined'){
    callback(CachedUrl.cache[url]);
  }else{
    $.ajax({async:false,url:url,success:function(html){
      CachedUrl.cache[url] = html;
      callback(html);
    }});
  }
};

var Template = {
  parse:function(template,data){
    var mytemplate = template;
    // console.log("Data: ");
    // console.log(data);
    var again = true;
    while(again){
      var pos = mytemplate.indexOf('[[');
      // console.log(pos);
      if(pos == -1){
        again = false;
      }else{
        var end_pos = mytemplate.indexOf(']]',pos);
        var name = mytemplate.substring(pos+2,end_pos);
        // console.log("From "+pos+" to "+end_pos+": Replace "+name+" = "+data[name]);
        mytemplate = mytemplate.replace('[['+name+']]',data[name]);
      }
    }
    return mytemplate;
  }
};

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
  reloadEnvelopes:function(force){
    if($('#dialog').dialog('isOpen') && !force){
      Finch.reload=true;
    }else{
      // Build a way to reload Envelopes using Ajax
      // Get json data
      $.getJSON('/envelopes.json', function(data){
        // Insert into all existing envelopes
        $.each(data.envelopes,function(){
          var item = this;
          CachedUrl.get((item.type == 'envelope' ? '/templates/envelope' : '/templates/real_account'),function(template){
            var replace_html = Template.parse(template,item);
            $('#envelope_'+item.id).replaceWith(replace_html);
          });
        });
      });
      // * * * *
      Finch.reload=false;
    }
  }
};

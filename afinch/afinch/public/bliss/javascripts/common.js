var debug = 0;

$(document).ready(function() {
  $("div#footer").hover(function(){
    $("div#footer").removeClass("opaque");
  },function(){
    $("div#footer").addClass("opaque");
  });
  
  $("#main").corner({
    tl: { radius: 6 },
    tr: { radius: 6 },
    bl: { radius: 6 },
    br: { radius: 6 },
    antiAlias: true,
    autoPad: true
  });
});

function flash_info(info){
  alert(info);
}

function flash_instruct(instruct){
  alert(instruct);
}

function flash_error(error){
  alert(error);
}

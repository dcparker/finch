/**
  Works with Prototype 1.6 and LowPro 0.5.
  
  This was originally written by Dan Webb (http://svn.danwebb.net/external/lowpro/trunk/behaviours/date_selector.js)
  and I just modified it a bit (added today link) and threw some styles on it to work it to my liking.
  
  Styles To Get You Started:
    table.calendar                         {width:250px; border:1px solid #ccc; background:#fff;}
    table.calendar td, table.calendar th   {text-align:center; padding:0; border-bottom:none;}
    table.calendar tr.day_header th        {background:#eee; padding:8px 0; border-top:1px solid #ccc;}
    table.calendar td                      {border:1px solid #ccc;}
    table.calendar a                       {text-decoration:none; display:block; padding:8px; color:#000;}
    table.calendar a:hover                 {background:#000; color:#fff;}
    table.calendar th  a                   {padding:10px 0;}
    table.calendar td.today  a             {background:#FFFF8B;}
    table.calendar td.today  a:hover       {background:#000; color:#fff;}
    table.calendar td.selected  a          {background:#000; color:#fff;}
    
  How To Use:
    1) Include prototype 1.6, lowpro 0.5 and this date_selector.js file.
    2) Add the following to an external javascript file or in the head of your page:
          Event.addBehavior({ 'input.date_picker' : DateSelector });
    3) Add class of date_picker to text input element.
          ie: <input type="text" name="st" value="01-22-2008" class="date_picker" />
*/

jQuery.fn.attach_date_selector = function(initial_date) {
  if(initial_date) {} else {
    initial_date = new Date();
  }
  
};
jQuery.log = function(message) {
  if(window.console) {
     console.debug(message);
  } else {
     alert(message);
  }
};

DateSelector = Behavior.create({
  initialize: function(options) {
    this.element.addClassName('date_selector');
    this.calendar = null;
    this.options = Object.extend(DateSelector.DEFAULTS, options || {});
    this.date = this.getDate();
    this._createCalendar();
  },
  setDate : function(value) {
    this.date = value;
    this.element.value = this.options.setter(this.date);
    
    if (this.calendar)
      setTimeout(this.calendar.element.hide.bind(this.calendar.element), 200);
  }, 
  _createCalendar : function() {
    var calendar = $div({ 'class' : 'date_selector' });
    document.body.appendChild(calendar);
    calendar.setStyle({
      position : 'absolute',
      zIndex : '500',
      top : Position.cumulativeOffset(this.element)[1] + this.element.getHeight() + 'px',
      left : Position.cumulativeOffset(this.element)[0] + 'px'
    });
    this.calendar = new Calendar(calendar, this);
  },
  onclick : function(e) {
    this.calendar.show();
    Event.stop(e);
  },
  // onfocus : function(e) {
  //     this.onclick(e);
  //   },
  getDate : function() {
    return this.options.getter(this.element.value) || new Date;
  }
});

Calendar = Behavior.create({
  initialize : function(selector) {
    this.selector = selector;
    this.element.hide();
    Event.observe(document, 'click', this.element.hide.bind(this.element));
  },
  show : function() {
    Calendar.instances.invoke('hide');
    this.date = this.selector.getDate();
    this.redraw();
    this.element.show();
    this.active = true;
  },
  hide : function() {
    this.element.hide();
    this.active = false;
  },
  redraw : function() {
    var html = '<table class="calendar">' +
               '  <thead>' +
               '    <tr><th class="back"><a href="#">&larr;</a></th>' +
               '        <th colspan="5" class="month_label">' + this._label() + '</th>' +
               '        <th class="forward"><a href="#">&rarr;</a></th></tr>' +
               '    <tr class="day_header">' + this._dayRows() + '</tr>' +
               '  </thead>' +
							 '  <tfoot>' + 
							 '  	<tr>' + 
							 '  		<td colspan="7" class="moveToToday">' + 
							 '  			<a href="#">Today</a>' + 
							 '  		</td>' + 
							 '  	</tr>' + 
							 '  </tfoot>' + 
               '  <tbody>';
    html +=    this._buildDateCells();
    html +=    '</tbody></table>';
    this.element.innerHTML = html;
  },
  onclick : function(e) {
    var source = Event.element(e);
    Event.stop(e);
    
    if ($(source.parentNode).hasClassName('day')) return this._setDate(source);
    if ($(source.parentNode).hasClassName('back')) return this._backMonth();
    if ($(source.parentNode).hasClassName('forward')) return this._forwardMonth();
    if ($(source.parentNode).hasClassName('moveToToday')) return this._move_to_today();
  },
  _setDate : function(source) {
    if (source.innerHTML.strip() != '') {
      this.date.setDate(parseInt(source.innerHTML));
      this.selector.setDate(this.date);
      this.element.getElementsByClassName('selected').invoke('removeClassName', 'selected');
      source.parentNode.addClassName('selected');
    }
  },
  _backMonth : function() {
    this.date.setMonth(this.date.getMonth() - 1);
    this.redraw();
    return false;
  },
  _forwardMonth : function() {
    this.date.setMonth(this.date.getMonth() + 1);
    this.redraw();
    return false;
  },
	_move_to_today : function() {
		var today = new Date();
		this.date.setMonth(today.getMonth());
		this.date.setYear(today.getFullYear());
		this.date.setDate(today.getDate());
		this.redraw();
		this.selector.setDate(this.date);
    this.element.getElementsByClassName('selected').invoke('removeClassName', 'selected');
		return false;
	},
  _getDateFromSelector : function() {
    this.date = new Date(this.selector.date.getTime());
  },
  _firstDay : function(month, year) {
    return new Date(year, month, 1).getDay();
  },
  _monthLength : function(month, year) {
    var length = Calendar.MONTHS[month].days;
    return (month == 1 && (year % 4 == 0) && (year % 100 != 0)) ? 29 : length;
  },
  _label : function() {
    return Calendar.MONTHS[this.date.getMonth()].label + ' ' + this.date.getFullYear();
  },
  _dayRows : function() {
    for (var i = 0, html='', day; day = Calendar.DAYS[i]; i++)
      html += '<th>' + day + '</th>';
    return html;
  },
  _buildDateCells : function() {
    var month = this.date.getMonth(), year = this.date.getFullYear();
    var day = 1, monthLength = this._monthLength(month, year), firstDay = this._firstDay(month, year);
    
    for (var i = 0, html = '<tr>'; i < 9; i++) {
      for (var j = 0; j <= 6; j++) {
        
        if (day <= monthLength && (i > 0 || j >= firstDay)) { 
          var classes = ['day'];
          
          if (this._compareDate(new Date, year, month, day)) classes.push('today');
          if (this._compareDate(this.selector.date, year, month, day)) classes.push('selected');
          
          html += '<td class="' + classes.join(' ') + '">' + 
                  '<a href="#">' + day++ + '</a>' + 
                  '</td>';
        } else html += '<td></td>';
      }
      
      if (day > monthLength) break;
      else html += '</tr><tr>';
    }
    
    return html + '</tr>';
  },
  _compareDate : function(date, year, month, day) {
    return date.getFullYear() == year &&
           date.getMonth() == month &&
           date.getDate() == day;
  }
});

DateSelector.DEFAULTS = {
  setter: function(date) {
    return [
      date.getMonth() + 1,
      date.getDate(),
			date.getFullYear()
    ].join('-');
  },
  getter: function(value) {
    var parsed = Date.parse(value);
    
    if (!isNaN(parsed)) return new Date(parsed);
    else return null;
  }
}

Object.extend(Calendar, {
  DAYS : $w('S M T W T F S'),
  MONTHS : [
    { label : 'January', days : 31 },
    { label : 'February', days : 28 },
    { label : 'March', days : 31 },
    { label : 'April', days : 30 },
    { label : 'May', days : 31 },
    { label : 'June', days : 30 },
    { label : 'July', days : 31 },
    { label : 'August', days : 31 },
    { label : 'September', days : 30 },
    { label : 'October', days : 31 },
    { label : 'November', days : 30 },
    { label : 'December', days : 31 }
  ]
});
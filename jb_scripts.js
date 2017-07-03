$(document).ready(function(){if (!window.__karma__) {jb_init(jQuery, CodeMirror, hasher, crossroads, URI)}});
function jb_init($, CodeMirror, hasher, crossroads, URI) {

var m = {};

var navs= $ ( '#navbar_items a' );
var controls= $ ( '.control' );
var slides= $ ( '.slide' );
var item = 0;

function whichItem(e) { 
  for (i = 0; i < 3; i++) {
  if ( e == controls[i] || e == navs[i]) {
      item= i;   
      }
    }
  } 
function toggleNav() {
  $ ( slides ).addClass( 'hide' ); 
  $ ( navs ).removeClass( 'hilite' ); 
  $ ( controls ).removeClass( 'hilite' ); 
  whichItem(this); 
  $ ( slides[item] ).removeClass( 'hide' );     
  $ ( navs[item] ).addClass( 'hilite' );    
  $ ( controls[item] ).addClass( 'hilite' ); 
  }
$ ( controls ).click( toggleNav ); 
$ ( navs ).click( toggleNav ); 

//////// ABOUT-Page ////// 

var divs= [$('#ziele'), $('#help'), $('#geschichte'), $('#impressum')];
var go2s= [$('#go2ziele'), $('#go2help'), $('#go2geschichte'), $('#go2impressum')]; 
var nexts= [$('#next_ziele'), $('#next_help'), $('#next_geschichte'), $('#next_impressum')]; 

$(go2s[0]).addClass('here');

for (a in divs) { 
  $( divs[a] ).hide(); 
  } 
  $( divs[0] ).show(); 


function go2next() {  
  for (a in divs) { $( divs[a] ).hide(); } 
  for (a in go2s) { $( go2s[a] ).removeClass('here'); } 
  $('#'+this.name ).show();
  $('#go2'+this.name).addClass('here');
  }
for (i in go2s) {
  $(go2s[i]).click(go2next);
  }
for (i in nexts) {
  $(nexts[i]).click(go2next);
  }
  
//////// Find-Page //////

  
var hideResults= $('.showResults').hide();

var resultsFramework;

/*var resultTogglingLinks= $('.suchOptionen a').click(function(e){
  e.preventDefault();
  getResultsHidden($(this).attr('href'))});*/

var getResultsLock = false;
var originalStack = "";
var raisedErrors = [];

function getResultsHidden(href) {
  if (getResultsLock) {
    var raisedError = Error("Do not call getResultsHidden() while a request is in progress!") ;
    raisedErrors.push(raisedError);
    throw raisedError;
  } else {
    var e = Error('');
    originalStack = e.stack.replace(/^Error.*/, '');
  }
  $('.showResults').hide('slow');
  resultsFramework = resultsFramework || $('.content > .showResults').clone();
  getResultsLock = true;
  $('.content > .showResults').load(href, function(unused1, statusText, jqXHR){
    /* chrome behaves synchronous here when the file is running from disk */
    if (jqXHR.status === 0) {
      /* emulate a delay that will always occur if the result is fetched from the real server */
      setTimeout(function(){onResultLoaded(statusText, jqXHR);}, 100);
    } else {onResultLoaded(statusText, jqXHR);}    
  });  
}

function onResultLoaded(statusText, jqXHR) {
  try {
    var ajaxParts = $('.content > .showResults .ajax-result'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol'),
        navResults = ajaxParts.find('.navResults'),
        frameWork = resultsFramework.clone();
    if (statusText === 'success' && raisedErrors.length === 0) {
      $('.pageindex .schlagworte.showResults').replaceWith(categoryFilter);
      frameWork.find('#showList > .navResults').replaceWith(navResults);
      frameWork.find('#showList > ol').replaceWith(searchResult);
    } else { handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText)]) }
    $('.content > .showResults').replaceWith(frameWork);
    $('.content > .showResults textarea.codemirror-data').each(function () {
      CodeMirror.fromTextArea(this,
        {
          readOnly: true,
          lineNumbers: true,
          foldGutter: true,
          gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
        });
    });
    $('.showResults').show('slow');
  } finally {
    getResultsLock = false;
  }
}

function handleGetErrors(frameWork, status, htmlErrorMessage) {  
  if (raisedErrors.length === 0) {
    frameWork.prepend($('<div class="ajax-error c'+(status-(status % 100))+'" data-errorCode="'+status+'">').append('<span>Server returned: '+status+'</span><br/>').append(htmlErrorMessage));
  } else {
    var errors = '<pre>Original call:\n'+originalStack+'</pre>';          
    for (var i = 0; i < raisedErrors.length; i++) {
      var stack = raisedErrors[i].stack.replace(/^Error.*/, '');
      errors += '<pre>'+raisedErrors[i].toString()+'\n'+stack+'</pre>'
    }
    frameWork.prepend($('<div class="ajax-error concurrency">').append(errors));
  }
  raisedErrors = [];
}
  
// Handler fuer .tipp (BS)

$( '.tipp' )
  .attr('title', 'Tipp')
  .children()
    .addClass('display') // :hover ausschalten
    .hide();  
$( document )
  .on('click', '.tipp',
    function () {
      $( this )
        .toggleClass ( 'q2x' )  // ? --> X
        .children().slideToggle( 'slow' );
      var title= 'Tipp'; 
      if( $(this).hasClass('q2x')){
        title = 'Tipp ausblenden';
      }        
      $(this).attr('title', title);  
    } 
  );  
  
  
// Handler fuer '<<' und '>>' (.hitList  scrollen), B.S.   
// Vorläufige Funktionalität: #hitRow wird hinter #fenster (overflow: hidden) ruckweise vorbeigezogen 
// ideal wäre: solang man die Maus gedrückt hält, scrollt das Feld, ev. mit zunemender Geschwindigkeit 

$( document )
  .on('click', '#pullRight',
  function () { 
      if( $( '#hitRow' ).position().left < 0) {
        $( '#hitRow' ).animate(  { left:'+='+ ($( '#fenster1').width()-16) }, 200 );
      } 
    }
  )
  .on('click', '#pullLeft',
  function () { 
    if( $( '#hitRow' ).position().left > 
        $( '#fenster1').width() - $( '#hitRow').width() ) {
      $( '#hitRow' ).animate(  { left:'-='+ ($( '#fenster1').width()-16)  }, 200 );
      } 
    }
  ); 
  
////////////////////////////////////////

$('#searchInput1').keypress(searchOnReturn);
function searchOnReturn(e) {
  if (e.which === 13) {
    e.preventDefault();
    doSearchOnReturn();
  }
}

function doSearchOnReturn() {
    var params = $('#searchform1').serialize(),
        baseUrl = $('#searchform1').attr('action')
    getResultsHidden(baseUrl+'?'+params);
};

m.doSearchOnReturn = doSearchOnReturn;

function executeQuery(query) {
    $('#searchInput1').val(query);
    doSearchOnReturn();
};

m.executeQuery = executeQuery;
  
// Handler fuer .showEntry select compact (BS)
// todo:  mit MODS/ LIDOS Handler vereinheitlichen

$( '.showOptions select' ).change( function() {  
  if(this.value == 'compact') {
    $( this ).closest('.showEntry').addClass('compact');
    }
  else {
    $( this ).closest(".showEntry").removeClass('compact');
    }
  });

// MODS/ LIDOS/  HTML umschalten (OS)
$(document).on('change', '.showResults .showOptions select', function(e){
   var target = $(e.target);
   var dataFormat = target.data("format")
   var curFormat = ( typeof dataFormat != 'undefined') ? dataFormat : "html";
   var format = target.val();
   target.data("format", format);
   var c = ".record-" + format;
   var div = target.closest(".showEntry").find(c);
   target.closest(".showEntry").find("[class^=record]").hide();
   div.show();
   if (format == 'lidos' || format == 'mods') {
        refreshCM(div);
   }
});

function refreshCM(div) {  
    var editor = div.find('.CodeMirror')[0].CodeMirror;
    editor.refresh();
}

//////// Schlagworte //////


/* 
// Handler für AND/OR, zu Demo-Zwecken (BS)
var toggleAnd = $('.andOr').click(
  function() { if (this.innerHTML== 'AND') this.innerHTML='OR'; 
               else this.innerHTML= 'AND'; }
  );
*/

function findQueryPartInHref(href) {
  var parsed = URI(href),
      conventionalQuery = parsed.query(true),
      fragment = parsed.fragment(),
      query = conventionalQuery === {} ? conventionalQuery : URI(fragment).query(true);
  return query;
}
  
$ ( '#facet-subjects').on('click', '.showResults a.zahl', function(e){
    e.preventDefault();
    var query = findQueryPartInHref($(this).attr('href')),
        subject = query.query;
    var currentQuery = $('#searchInput1').val();
    var newQuery = currentQuery === "" ? subject : currentQuery + " and " + subject;
    executeQuery(newQuery);
});

// Handler für Klick auf (+) in Resultatliste
$(document).on('click', '.results .plusMinus', function (e) {
    e.preventDefault();
    var fullEntryIsShown = $(this).hasClass("close");
    $ ( this ).toggleClass( 'close' );
    if ( fullEntryIsShown ) {
        $ ( this ).nextAll( 'div' ).hide('fast');
    } else {
        $ ( this ).next('.showEntry').show('slow');
    }
}); 

// Handler für Klick auf "Resultate"
$('.content').on('click', '.showResults a.zahl', function (e) {
    e.preventDefault();
    var query = findQueryPartInHref($(this).attr('href')).query;
    executeQuery(query);
});

// Handler für Klick auf alphabetische Liste für Autoren oder Werktitel 
// TODO: Anpassen an Kontext (BS)
$('.suchOptionen a').click(function(e){
    e.preventDefault();
    var index = $(e.target).closest("td").attr("data-index");
    var term = $(e.target).text() + "*";
    executeQuery(index+"="+term);
});
 

// Schlagwortbaum oeffnen und schliessen (BS)
// Auskommentiert wegen moegl. Konflikt mit anderen Skripts (BS)

var plusMinus='.schlagworte .plusMinus';
var ols= $ ( '.schlagworte li li ol' );

  // Anfangszustand; spaeter aendern
$ ( plusMinus ).addClass( 'close' );   
$ ( ols ).show(); 

var showAll =  $ ( '#aO' ).click( 
  function ( ) { 
    $ ( '.schlagworte li li ol' ).show ( 'slow' );
    $(plusMinus).addClass( 'close' );     
    }
  );  
var closeAll =  $ ( '#aC' ).click( 
  function ( ) { 
    $ ( '.schlagworte li li ol' ).hide ( 'slow' );
    $(plusMinus).removeClass( 'close' );     
    }
  ); 
$(document).on('click', plusMinus, toggleNext);
function toggleNext(e) {
    $ (this).nextAll( 'ol' ).toggle( 'slow' );
    $ (this).toggleClass( 'close' );
    }

window.jb80 = m;

}
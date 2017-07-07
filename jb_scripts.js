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
    var self = this;
    /* chrome behaves synchronous here when the file is running from disk */
    if (jqXHR.status === 0) {
      /* emulate a delay that will always occur if the result is fetched from the real server */
      setTimeout(function(){onResultLoaded.apply(self, [statusText, jqXHR]);}, 100);
    } else {onResultLoaded.apply(self, [statusText, jqXHR]);}    
  });  
}

function onResultLoaded(statusText, jqXHR) {
  try {
    var ajaxParts = $('.content > .showResults .ajax-result'),
        ajaxPartsDiagnostics = $('.content > .showResults sru\\:diagnostics'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol'),
        navResults = ajaxParts.find('.navResults'),
        frameWork = resultsFramework.clone();
    if (statusText === 'success' && raisedErrors.length === 0 && ajaxPartsDiagnostics.length === 0) {
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

var navR = $( '.navResults' );
var countR = $( '.countResults');
var fenster = $( '#fenster1');
var hitRow = $( '#hitRow');
var hits = $( '#hitRow .hits' );
var runTime = hits.length*50;
var FW = 160;
var hitsW = $( '#hitRow').width();
/*
function arrangeHitlist() {
  // max. Weite für fenster
  FW =  ($( '.navResults' ).width()-$( '.countResults' ).width() )/2; 
  // berechne width aller hits
  //for (i=1;i<hits.length;i++) {
    //hitsW += $( hits[i] ).outerWidth();
  //}
  
alert ('FW = '+ FW + '; hitsW = ' + hitsW);
  //verstecke Navigationselemente
  $( '.pull' ).hide();
  // Anpassen des Fensters an Hits
  if(hits.length < 3) 
    $( fenster ).hide();
  else if (hitsW <= FW)
    $( fenster ).width(hitsW);
  else {
    $( fenster ).width(FW);
    $( '.pull' ).show();
  }
} 
  */  
//$( document ).on('click',  arrangeHitlist); 

$( document ).on( 'mousedown', '#pullLeft', 
  function () {  
      if( $( '#hitRow' ).position().left < 0) {
      $( '#hitRow' ).animate(  { left: 0 }, runTime );
      } 
    }
); 
$( document ).on( 'mousedown', ' #pullRight', 
  function () {  
    var maxL = ($( '#hitRow' ).width() - $(  '#fenster1' ).width())*-1;
    if( $( '#hitRow' ).position().left > maxL ) {
      $( '#hitRow' ).animate(  { left:  maxL }, runTime );
      } 
    }
  );
////////////////////////////////////////

$( document )
  .on('click', '.hitList a.hits', onFetchMoreHits);
function onFetchMoreHits(e) {
  var query = findQueryPartInHref($(this).attr('href'));
  e.preventDefault();
  doSearchOnReturn(query.startRecord);
}
////////////////////////////////////////

$('#searchInput1').keypress(searchOnReturn);
function searchOnReturn(e) {
  if (e.which === 13) {
    e.preventDefault();
    doSearchOnReturn();
  }
}

function doSearchOnReturn(optStartRecord) {    
    var startRecord = optStartRecord || 1,
        baseUrl = $('#searchform1').attr('action')
    $('#searchform1 input[name="startRecord"]').val(startRecord);
    getResultsHidden(baseUrl+'?'+$('#searchform1').serialize());
};

m.doSearchOnReturn = doSearchOnReturn;

function executeQuery(query) {
    $('#searchInput1').val(query);
    doSearchOnReturn();
};

m.executeQuery = executeQuery;
  
// Handler fuer .showList select
$(document).on('change', '#showList > .showOptions select', function(e){
   var target = $(this),
       sortBy = target.val(),
       currentQuery = $('#searchInput1').val(),
       sortLessQuery = currentQuery.replace(/ sortBy .*$/, ''),
       newQuery = sortLessQuery + ' sortBy ' + sortBy;
   if (sortBy === '-') {return;}
   target.data("sortBy", sortBy);
   $('#searchInput1').val(newQuery);
   doSearchOnReturn();
});

// MODS/ LIDOS/  HTML umschalten (OS)
$(document).on('change', '.showResults .showOptions select', function(e){
   var target = $(e.target),
       dataFormat = target.data("format")
       curFormat = ( typeof dataFormat != 'undefined') ? dataFormat : "html",
       format = target.val(),
       target.data("format", format),
       c = ".record-" + format;
   if (format === 'compact') {
     c = ".record-html";
   }
   var entry = target.closest(".showEntry"),
       div = entry.find(c);
   target.closest(".showEntry").find("[class^=record]").hide();
   div.show();
   if (format === 'compact') {
     entry.addClass('compact');
   } else {
     entry.removeClass('compact');
   }
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
        subject = query.query,
        currentQuery = $('#searchInput1').val(),
        newQuery = currentQuery === "" ? subject : currentQuery + " and " + subject,
        plusMinus = $(this).prevAll('.plusMinus');
    if (plusMinus.length === 1 && !plusMinusDependentIsShown(plusMinus)) {
      toggleNextSubtree.apply(plusMinus, [e]);
      setTimeout(function(){
        executeQuery(newQuery)
      }, 2000);
    } else {
    executeQuery(newQuery);
    }
});
function plusMinusDependentIsShown(aPlusMinus) {
  return $(aPlusMinus).hasClass("close")
}

// Handler für Klick auf (+) in Resultatliste
$(document).on('click', '.results .plusMinus', openOrCloseDetails);
function openOrCloseDetails(e) {
    e.preventDefault();
    if ( plusMinusDependentIsShown(this) ) {
        $ ( this ).nextAll( 'div' ).hide('fast');
    } else {
        $ ( this ).next('.showEntry').show('slow');
    }    
    $ ( this ).toggleClass( 'close' );
}

// Handler für Klick auf "Resultate"
$('.content').on('click', '.showResults a.zahl, .showResults a.stichwort', function (e) {
    e.preventDefault();
    var query = findQueryPartInHref($(this).attr('href')).query;
    executeQuery(query);
});

// Handler für Klick auf alphabetische Liste für Autoren oder Werktitel 
$('.suchOptionen .abc a').click(function(e){
    e.preventDefault();
    var index = $(e.target).closest("td").attr("data-index");
    var term = $(e.target).text() + "*";
    executeQuery(index+"="+term);
});

$('a.code').click(function(e){
    e.preventDefault();
    var query = $(this).text();
    executeQuery(query);
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
$(document).on('click', plusMinus, toggleNextSubtree);
function toggleNextSubtree(e) {
    $ (this).nextAll( 'ol' ).toggle( 'slow' );
    $ (this).toggleClass( 'close' );
    }

window.jb80 = m;

}
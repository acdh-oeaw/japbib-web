$(document).ready(function(){if (!window.__karma__) {jb_init(jQuery, CodeMirror, hasher, crossroads, URI)}});
function jb_init($, CodeMirror, hasher, crossroads, URI) {

var m = {};

// Handler fuer Seitenwechsel (BS)

var mainPages = ['about', 'find', 'thesaurus'];
var aboutSubpages =  ['ziele', 'help', 'geschichte', 'impressum'];

function go2page(link) {  
  $( '.slide' ).hide(); 
  $( '.control' ).add( $( '#navbar_items a' ) ).removeClass( 'hilite' ); 
  $( '#'+link ).show();     
  $('#'+link+'_control' ).add( $( '#navbar_items a[href~="#'+link+'"]' ) ).addClass( 'hilite' );    
}
function go2subPage(link) {
  $( '#about .content div').hide();
  $( '#about .pageindex a' ).removeClass('here');
  $( '#'+link ).show();
  $( '#about .pageindex a[href~="#'+link+'"]' ).addClass( 'here' );
  // go to #about
  go2page('about');
}

mainPages.forEach( function(link) {
  crossroads.addRoute(link, function() {
    go2page(link); 
    //hasher.replaceHash(link);
  });
}); 
aboutSubpages.forEach( function(link) {
  crossroads.addRoute(link, function() {
    go2subPage(link); 
    //hasher.setHash(link);
  });
});

go2page('about');
go2subPage('ziele');

//setup crossroads

crossroads.routed.add(console.log, console); //log all routes
//setup hasher
function parseHash(newHash, oldHash){
  crossroads.parse(newHash);
}
hasher.initialized.add(parseHash); //parse initial hash
hasher.changed.add(parseHash); //parse hash changes
hasher.init(); //start listening for history change

 /**/
 
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
  var currentSorting = $('#showList > .showOptions select').val();
  $('.showResults').hide('slow');
  resultsFramework = resultsFramework || $('.content > .showResults').clone();
  getResultsLock = true;
  $('.content > .showResults').load(href, function(unused1, statusText, jqXHR){
    var self = this;
    /* chrome behaves synchronous here when the file is running from disk */
    if (jqXHR.status === 0) {
      /* emulate a delay that will always occur if the result is fetched from the real server */
      setTimeout(function(){onResultLoaded.apply(self, [statusText, jqXHR, currentSorting]);}, 100);
    } else {onResultLoaded.apply(self, [statusText, jqXHR, currentSorting]);}    
  });  
}

function onResultLoaded(statusText, jqXHR, currentSorting) {
  try {
    var ajaxParts = $('.content > .showResults .ajax-result'),
        ajaxPartsDiagnostics = $('.content > .showResults sru\\:diagnostics'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol'),
        navResults = ajaxParts.find('.navResults'),
        frameWork = resultsFramework.clone();
    frameWork.find('.showOptions select').val(currentSorting);
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
    arrangeHitlist(); // Treffernavigation (BS) s.u.
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
   
// Handler fuer positionieren und scrollen der Trefferliste << >> (BS)       
 
var hits = $( '#hitRow .hits' ), //Treffer innerhalb der beweglichen hitRow
    runTime = hits.length*50, // scroll-Dauer
    hitsW = 160,  // Weite fuer HitRow
    FW = 160, // Fensterweite
    posLeft = 0, // Pos. v. hitRow
    maxL = 0, // maximale Verschiebung nach links
    spaceR = FW/2; 

function arrangeHitlist() { // Funktion wird von onResultLoaded aufgerufen
  hitsW = $( '#hitRow').width();
  // max. Weite fuer fenster
  FW =  ($( '.navResults' ).width()-$( '.countResults' ).width() )/2; 
  // Nav-Pfeile anzeigen oder verstecken
  if (FW < hitsW) {
    $( '#fenster1' ).width(FW);
    $( '.pull').css( "visibility", "visible");
  }
  else{
    $( '#fenster1' ).width(hitsW);
    $( '.pull').css( "visibility", "hidden");
  } 
  
  /////////  .here  positionieren /////////
  maxL = FW - hitsW;  
    // wenn hitRow > Fenster und .here innerhalb von hitRow
  if ( maxL < 0 && $('#hitRow .here').length > 0 ) {
      // wenn here nicht mehr sichtbar
    if ( $('#hitRow .here').position().left > FW - $('#hitRow .here').width() ) {
        // wenn rechts genug Platz
      var spaceR = (FW - $('#hitRow .here').width())/2 ;
      if ( $('#hitRow').width()-($('#hitRow .here').position().left) > spaceR ) {        
        posLeft = -$('#hitRow .here').position().left + spaceR;
      }
      else { // maximale left-Verschiebung 
        posLeft = maxL;
      } 
    } 
  } 
    // wenn .here an letzter Stelle
  else if ($('.last.here').length > 0 ) {       
    posLeft = maxL;
  }
    // hitRow in Hinblick auf .here verschieben 
  $( '#hitRow' ).css( 'left', posLeft);
  stylePull();
} 
function stylePull() { 
  $('#pullLeft, #pullRight').addClass('active');
  if ($( '#hitRow' ).position().left >= 0 ) 
    $( '#pullLeft' ).removeClass('active');
  if ($( '#hitRow' ).position().left-1 <= maxL ) 
    $( '#pullRight' ).removeClass('active');
}

   ///////// hitRow scollen /////////
$( document ).on( 'mousedown', '#pullLeft', 
  function () {  
    if( $( '#hitRow' ).position().left < 0) {
      $( '#hitRow' ).animate(  { left: 0 }, runTime, stylePull ); 
    } 
  }
); 
$( document ).on( 'mousedown', ' #pullRight', 
  function () {     
    if( $( '#hitRow' ).position().left > maxL ) {
      $( '#hitRow' ).animate(  { left:  maxL }, runTime, stylePull );
    } 
  }
); 
$( document ).on( 'mouseup', '#pullLeft, #pullRight', 
  function () {  
    $( '#hitRow' ).stop();  
    stylePull();
  }
); 

  
///////////////////////////////////////

$( document )
  .on('click', '.hitList a.hits', onFetchMoreHits);
function onFetchMoreHits(e) {
  var query = findQueryPartInHref($(this).attr('href'));
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

// Handler fuer Klick auf (x) in Einzeleintrag (BS)
$(document).on('click', '.closeX', function() {
  var closestPlusMinus=$( this ).closest( 'li' ).find(' .plusMinus ').trigger('click');
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
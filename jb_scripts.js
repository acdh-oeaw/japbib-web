$(document).ready(function(){if (!window.__karma__) {jb_init(jQuery, CodeMirror, hasher, crossroads, URI)}});
function jb_init($, CodeMirror, hasher, crossroads, URI) {

var m = {},
    getResultsLock = false,
    getResultsErrorTracker = {
      originalStack:"",
      raisedErrors:[]
    }

// Handler fuer Seitenwechsel (BS)

var mainPages = ['about', 'find', 'thesaurus'];
var aboutSubpages =  ['ziele', 'help', 'geschichte', 'bildnachweise', 'impressum'];

function go2page(link) {  
  $( '.slide' ).hide(); 
  $( '#'+link ).show();     
  $( '.control' ).add( $( '#navbar_items a' ) ).removeClass( 'hilite' ); 
  $('#'+link+'_control' ).add( $( '#navbar_items a[href~="#'+link+'"]' ) ).addClass( 'hilite' );   
  fixWishlist();  // toggle position thesaurus wishlist, s.u.
}
function go2subPage(link) {
  go2page('about');
  document.body.scrollTop= // For Chrome, Safari and Opera
  document.documentElement.scrollTop = 0; // Firefox and IE 
  $.each($( '#about .content div'), function() {
    if( $(this).is(':visible') && this.id !== link)
       $(this).fadeOut( 'slow', function() { 
         $( '#'+link ).fadeIn('slow');
       });
  });
  $( '#about .pageindex a' ).removeClass('here');
  $( '#about .pageindex a[href~="#'+link+'"]' ).addClass( 'here' );
}

mainPages.forEach( function(link) {
  crossroads.addRoute(link+'{?query}', function(query) {
    switch(link) {
    case 'thesaurus': break;
    case 'find':
    default: fillInSearchFrom(query);
    }
    go2page(link); 
    doSearchOnReturn();
  });
  crossroads.addRoute(link, function(query) {
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

//go2page('about');
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

function getResultsHidden(href) {
  checkLock('getResultsHidden()', getResultsLock, getResultsErrorTracker);
  var currentSorting = $('#sortBy').val();
  resultsFramework = resultsFramework || $('.content > .showResults').clone();
  $('.showResults').hide('slow');
  $('.ladeResultate').show();
  getResultsLock = true;
  $('.content > .showResults').load(href, function(unused1, statusText, jqXHR){
      callbackAlwaysAsync(this, jqXHR, onResultLoaded, [statusText, jqXHR, currentSorting]);
  });  
}

function checkLock(callerName, aLock, anErrorTracker) {  
  if (aLock) {
    var raisedError = Error("Do not call "+callerName+" while a request is in progress!") ;
    anErrorTracker.raisedErrors.push(raisedError);
    throw raisedError;
  } else {
    try {throw Error('')} catch(e) { 
    anErrorTracker.originalStack = e.stack.replace(/^Error.*/, '');
    }
  }
}

function callbackAlwaysAsync(self, jqXHR, onResultLoaded, argumentsList) {
    /* chrome behaves synchronous here when the file is running from disk */
    if (jqXHR.status === 0) {
      /* emulate a delay that will always occur if the result is fetched from the real server */
      setTimeout(function(){onResultLoaded.apply(self, argumentsList);}, 1000);
    } else {onResultLoaded.apply(self, argumentsList);}    
}

function onResultLoaded(statusText, jqXHR, currentSorting) {
  try {
    var ajaxParts = $('.content > .showResults .ajax-result'),
        ajaxPartsDiagnostics = $('.content > .showResults sru\\:diagnostics'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol'),
        navResults = ajaxParts.find('.navResults'),
        frameWork = resultsFramework.clone();
    //frameWork.find('.showOptions select').val(currentSorting);
    if (statusText === 'success' && getResultsErrorTracker.raisedErrors.length === 0 && ajaxPartsDiagnostics.length === 0) {
      $('.pageindex .schlagworte.showResults').replaceWith(categoryFilter);
      frameWork.find('#showList > .navResults').replaceWith(navResults);
      frameWork.find('#showList > ol').replaceWith(searchResult);
    } else { handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText), getResultsErrorTracker]) }
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
    $('.ladeResultate').hide();        
    $('#find .schlagworte li li ol').hide ();  //Anfangszustand bei neuer Abfrage
    $('.showResults').show('slow', arrangeHitlist);    // arrangeHitlist = Treffernavigation (BS) s.u.     
  } finally {
    getResultsLock = false;
  }
}

function handleGetErrors(frameWork, status, htmlErrorMessage, anErrorTracker) {  
  if (anErrorTracker.raisedErrors.length === 0) {
    frameWork.prepend($('<div class="ajax-error c'+(status-(status % 100))+'" data-errorCode="'+status+'">').append('<span>Server returned: '+status+'</span><br/>').append(htmlErrorMessage));
  } else {
    var errors = '<pre>Original call:\n'+anErrorTracker.originalStack+'</pre>';          
    for (var i = 0; i < anErrorTracker.raisedErrors.length; i++) {
      var stack = anErrorTracker.raisedErrors[i].stack.replace(/^Error.*/, '');
      errors += '<pre>'+anErrorTracker.raisedErrors[i].toString()+'\n'+stack+'</pre>'
    }
    frameWork.prepend($('<div class="ajax-error concurrency">').append(errors));
  }
  anErrorTracker.raisedErrors = [];
}
  
// Handler fuer .tipp (BS)

$( '.tipp' )
  .attr('title', 'Tipp')
  .children().hide();  
$( document ).on('click', '.tipp', function () {
  $( this )
    .toggleClass ( 'q2x' )  // ? --> X
    .children().slideToggle( 'slow' );
  var title= 'Tipp'; 
  if( $(this).hasClass('q2x')){
    title = 'Tipp ausblenden';
  }        
  $(this).attr('title', title);  
});    

// Handler fuer suchOptionen (BS)

// Navigation
$('.examples td[data-index]').hide();
$('.examples td[data-index]:first').show();
$('.examples th').click(function() {
  $('.examples th').removeClass('here');
  $('.examples td[data-index]').fadeOut('slow');
  $(this).addClass('here');
  $( this).siblings('td[data-index]').fadeIn('slow');
});

// Suche nach Datum  

var years = $('.year a'),
    rangeSelected = false,
    startSelected = 0,
    endSelected = 0;

$(document).on('click', '.year a', function(e){
  e.preventDefault(); 
     //fruehere Auswahl aufheben
  if (rangeSelected === true) {
    $( years ).removeClass('selected');
    rangeSelected = false;
    startSelected = 0;
    endSelected = 0;
  }
  $( this ).toggleClass('selected');
     //neue Gruppe auswaehlen
     //erste Auswahl
  $.each(years, function(i)  {
    if( $(years[i]).hasClass('selected')) {
      startSelected= i;
      return false;
    } 
  }); 
     //letzte Auswahl
  $.each($(years), function(i) {
    if( $(years[i]).hasClass('selected')) {
      endSelected= i;
    } 
  }); 
    // Gruppe selektieren    
  if (startSelected < endSelected) {   
    for (i= startSelected; i <= endSelected; i++) {
      $( years[i] ).addClass('selected'); 
    } 
    rangeSelected = true;
  }
    // Suche formulieren
  var inputQuery = $( '#searchInput1' ).val();  
  inputQuery = inputQuery.replace(/[and ]*date[=><]+[\d-and te=><]+/,'');

  if ( $('.year .selected').length > 0) {
    var dateQuery= inputQuery? ' and date': 'date' ;
    if (startSelected===endSelected) 
      dateQuery += '='+(1980+startSelected);
    else 
      dateQuery += '>='+(1980+startSelected) + ' and date<='+ (1980+endSelected);
    inputQuery += dateQuery;
  }
  $( '#searchInput1' ).val(inputQuery);
});

// Suchhilfe

$('#searchInput1').on('keyup', function() {
  var eingetippt= ($(this).val()); 
  var rex1 = /[=* "]([^=* "]{4})/;
  var rex2= /^(?!auth|subj|titl)[^=* "]{4}/;
  var match = rex1.exec(eingetippt) || rex2.exec(eingetippt);
  var q = '';
    // Ergebnisse vor ..= ausschließen
  if ( match && match[1]) 
    q= match[1];
  else if ( match ) 
    q= match[0]; 

  if (q) { 
    $('#searchHelp b').text(q);
    if($('#searchHelp td').is(':hidden'))
       $('#searchHelp th').trigger('click');
  }      
}); 

// Handler fuer positionieren und scrollen der Trefferliste << >> (BS)        

function arrangeHitlist() { // Funktion wird von onResultLoaded aufgerufen
  if ( $( '#hitRow' ) !== 'undefined') {
    var maxL = 0, 
        posLeft = 0,
        hits = $( '#hitRow .hits' ), //Treffer innerhalb der beweglichen hitRow
        hitsW = $( '#hitRow').width(), 
        FW =  ($( '.navResults' ).width()-$( '.countResults' ).width() )/2, // max. Weite fuer fenster    
        spaceR = FW/2,
        runTime = hits.length*50; // scroll-Dauer  
    // Nav-Pfeile anzeigen oder verstecken
    if (FW < hitsW) {
      $( '#fenster1' ).width(FW);
      $( '.pull').css( "visibility", "visible");
    }
    else {
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
} 
  
///////////////////////////////////////

$( document )
  .on('click', '.hitList a.hits', onFetchMoreHits);
function onFetchMoreHits(e) {
  e.preventDefault();
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

function fillInSearchFrom(query) {
  $.each(query, function(key, value){
    $('#searchform1 input[name="'+key+'"]').val(value);
  });
}

function doSearchOnReturn(optStartRecord) {    
    var startRecord = optStartRecord || 1,
        baseUrl = $('#searchform1').attr('action'),
        query = $('#searchform1 input[name="query"]').val(),
        sortBy = query.indexOf('sortBy') === -1 ?
                 query.replace(/^([^=]+).*/, '$1') :
                 query.replace(/^.*sortBy\s+(.*)$/, '$1')
    $('#searchform1 input[name="startRecord"]').val(startRecord);
    //$('#showList > .showOptions select').val(sortBy);
    $('#sortBy').val(sortBy);
    getResultsHidden(baseUrl+'?'+$('#searchform1').serialize());
};

m.doSearchOnReturn = doSearchOnReturn;

function executeQuery(query) {
    $('#searchInput1').val(query);
    doSearchOnReturn();
};

m.executeQuery = executeQuery;

// Handler fuer Resultate pro Seiten 

$("#maximumRecords").change(function(e){
   doSearchOnReturn();
});
  
// Handler fuer .showList select
//$(document).on('change', '#showList > .showOptions select', function(e){
$(document).on('change', '#sortBy', function(e){
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

var categoryFramework;
var getCategoriesLock = false;
var getCategoriesErrorTracker = {
  originalStack:"",
  raisedErrors:[]
}

function loadCategory(href) {
  checkLock('loadCategory()', getCategoriesLock, getCategoriesErrorTracker);
  categoryFramework = categoryFramework || $('#thesaurus #showList').clone();
  $('#thesaurus #showList').hide('slow');
  getCategoriesLock = true;
  $('#thesaurus #showList').load('thesaurus', function(unused1, statusText, jqXHR){
      callbackAlwaysAsync(this, jqXHR, onCategoryLoaded, [statusText, jqXHR]);
  });
}

function onCategoryLoaded(statusText, jqXHR) {
  try {
    var ajaxParts = $('#thesaurus #showList .ajax-result'),
        ajaxPartsDiagnostics = $('#thesaurus #showList sru\\:diagnostics'),
        categories = ajaxParts.find('ol.schlagworte'),
        frameWork = categoryFramework.clone();
    if (statusText === 'success' && getCategoriesErrorTracker.raisedErrors.length === 0 && ajaxPartsDiagnostics.length === 0) {
      frameWork.find('ol.schlagworte').replaceWith(categories);
    } else { handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText), getResultsErrorTracker]) }
    $('#thesaurus #showList').replaceWith(frameWork);
    $('.ladeSchlagworte').hide();    
    $('#thesaurus .schlagworte li li ol').hide ();  //Anfangszustand bei Neuladen
    $('#thesaurus #showList').show('slow');  
  } finally {
    getCategoriesLock = false;
  }
}

loadCategory();

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
        $ ( this ).nextAll( 'div' ).hide('slow');
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

$('#find a.code').click(function(e){
    e.preventDefault();
    var query = $(this).text();
    executeQuery(query);
});
 
// Handler für Suchfeld:  Clear Search und search (BS)

$(document).on('keyup mouseup', 'body', toggleXQ );

function toggleXQ() {   
  if ( $('#searchInput1').val().length < 1) {
    $('#clearSearch').hide();
    $('#doSearch').css({ 'opacity':'.1', 'cursor':'default', 'background': 'transparent' });
  }
  else { 
    $('#clearSearch').show(); 
    $('#doSearch').removeAttr("style");
  }  
}
$(document).on( 'click', '#clearSearch', function() {  
  $( '.showResults').hide(); 
  $('#searchInput1').val('');
  hasher.prependHash = '';
  hasher.setHash('find');
  toggleXQ();
});
$(document).on( 'click', '#doSearch', function(e) {   
  e.preventDefault();
  var query = $('#searchInput1').val();
  if (query.length)
    executeQuery(query); 
  toggleXQ();
});

// Schlagwortbaum oeffnen und schliessen (BS)

var plusMinus = '.schlagworte .plusMinus', 
    ols=  '#thesaurus .schlagworte li li ol';

  // Anfangszustand 
$( plusMinus ).removeClass( 'close' );   
$( ols ).hide();  

$(document).on('click', '#aO',  function ( ) { 
  $( ols ).show( 'slow' );
  $( plusMinus ).addClass( 'close' );     
}); 
$(document).on('click', '#aC',  function ( ) { 
  $( ols ).hide( 'slow' );
  $( plusMinus ).removeClass( 'close' );     
}); 

$(document).on('click', '.schlagworte .plusMinus', toggleNextSubtree);
function toggleNextSubtree(e) {
    if (e.currentTarget !== e.target) {return;}
    $ (this).nextAll( 'ol' ).toggle( 'slow' );
    $ (this).toggleClass( 'close' );
    }

// Handler fuer Kombinieren von Schlagworten im Thesaurus, #wishList (BS)

var $wishList= $( '#wishList' ), 
    ausgewaehlt= [],
    maxWishes= 3;

$wishList.empty();

function neueAuswahl(newTerm, newConj, remove) {   
  var termIsNew = true, 
      conjIsNew = newConj? true: false,
      newConj= newConj || 'AND';
  if (ausgewaehlt.length)
    for( i in ausgewaehlt) {
      if( ausgewaehlt[i].term && ausgewaehlt[i].term == newTerm ) {
        termIsNew = false;  
        if (conjIsNew) ausgewaehlt[i].conj= newConj;
      } 
    }     
  if( termIsNew ) 
    ausgewaehlt.unshift( {term: newTerm, conj:newConj} );  
    // auf 3 begrenzen
  if (ausgewaehlt.length > maxWishes)
    ausgewaehlt.pop();  
    // Zeile etfernen
  if (remove) {   
    for( i in ausgewaehlt)
      if( ausgewaehlt[i].term && ausgewaehlt[i].term == newTerm )
        ausgewaehlt.splice(i, 1); 
  } 
    // AND entfernen
  if(ausgewaehlt.length)
    ausgewaehlt[ausgewaehlt.length-1].conj='';
  
  /**/
    //console.log(ausgewaehlt.length); 
    
  baueListe();
}
function baueListe(){
  var $ue= $( '#thesaurus h4');
  var newWishes= '';
  var newQ= '';
  $.each( ausgewaehlt, function( i, qObj ) { 
    newWishes +='<li><i class="fa fa-check-square-o" title="Auswahl löschen"></i>'+ 
      qObj.term +
      '<a class="andOr" title="Suche eingrenzen (AND)/ erweitern (OR)">' +
      qObj.conj+
      '</a></label></li>';
    newQ += 'subject="' + qObj.term + '" ' +  qObj.conj + ' ';  
  });   
  newQ= encodeURIComponent(newQ);
  $wishList.empty();
  if (ausgewaehlt.length > 0) {
    $ue.text( ' Ausgewählte Schlagworte ' );
    $wishList
      .append( '<ul>' + newWishes + '</ul>' )
      .append( '<a class="fa-search" id="abfrage" href="#find?query=' + newQ + '" title= "Abfrage auf der Suchseite">Abfrage</a>' );
  }
  else  {
    $ue.text( 'Schlagworte auswählen' );
  }
}

  // Auswahl entfernen
$(document).on('click', '#wishList li .fa',  function () { 
  var term = $( this ).parent().clone().find('> a').remove().end().text();
  neueAuswahl( $.trim( term ),'', 1 ); 
});

  //  AND/OR/NOT[?]
$( document).on( 'click', '.andOr', function(e) { 
  e.preventDefault();
  var term = $( this ).parent().clone().find('> a').remove().end().text(),
      conj = ( this.innerHTML == 'AND')? 'OR' : 
    // ( this.innerHTML == 'OR')? 'NOT': 
      'AND';       
   neueAuswahl(term, conj); 
});

$( document).on( 'click', '#thesaurus .schlagworte a.zahl', function(e) {
  e.preventDefault();  
  var term= $( this ).prevAll( '.term:first' ).html();
  neueAuswahl(term); 
  //console.log( term );
}); 

 //wishlist fixieren (BS)

function fixWishlist() {
  var top=  $( '#wrapAbsolute').offset().top -40;
  if ($( document ).scrollTop() >= top) {
    $( '#wrapFixed').css({
     'position':'fixed', 
     'top': 40+'px'
    });
  }
  else {
    $( '#wrapFixed').css({
      'position':'static',
      'top': 'auto'
    });
  }
} 
$( document ).on( 'scroll', fixWishlist);

/////////////

window.jb80 = m;

}
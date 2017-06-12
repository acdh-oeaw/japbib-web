$(document).ready(jb_init);
function jb_init() {

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

//////// ABOUT ////// 

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
  
//////// Find //////

var toggleAnd = $('.andOr').click(
  function() { if (this.innerHTML== 'AND') this.innerHTML='OR'; 
               else this.innerHTML= 'AND'; }
  );
  
var hideResults= $('.showResults').hide();
/*var resultTogglingLinks= $('.suchOptionen a').click(function(e){
  e.preventDefault();
  toggleResults($(this).attr('href'))});*/
function toggleResults(href) {  
  // todo (BS, 10.6.): 
    //function besser auf .showList anwenden statt auf .showResults
    //neu kreiertes div muss bei neuer Frage wieder gelöscht werden
    //Zeige Anzahl der Resultate in neuem span: $('#countResults') 
  $('.showResults').hide('slow');
  $('.showResults ol').remove();
  var frameWork = $('.content > .showResults').clone();
  $('.content > .showResults').load(href, function(){
    var ajaxParts = $('.content > .showResults .ajax-result'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol');
    $('.pageindex .schlagworte.showResults').replaceWith(categoryFilter);
    frameWork.find('#showList').append(searchResult);
    ajaxParts.replaceWith(frameWork);
    $('.showResults').show('slow');
  // Erste Erklaerung in ein Fragezeichen verpacken:
    // todo (BS 10.6.): , if Resultate > 0, addClass(''erklärung''), else removeClass  
    $('#erklärung').toggleClass('erklärung'); 
  });
    
  }
var hideEntry= $('.showEntry').hide();
var toggleEntry= $('#showList a').click(
  function() {  
    $('.showEntry').toggle('slow');       
    }
  );

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
    toggleResults(baseUrl+'?'+params);
};

function executeQuery(query) {
    $('#searchInput1').val(query);
    doSearchOnReturn();
};

//////// Schlagworte //////
  
$ ( '#facet-subjects').on('click', 'a', function(e){
    e.preventDefault();
    var subject = $(e.target).parent().children('.sup').text();
    var currentQuery = $('#searchInput1').val();
    var newQuery = currentQuery === "" ? "subject="+subject : currentQuery + " AND " + "subject=" + subject;
    executeQuery(newQuery);
});

// Handler für Klick auf (+) in Resultatliste
$( '.showResults' ).on('click', '.sup', function (e) {
    e.preventDefault();
    var fullEntryIsShown = $(this).hasClass("close");
    $ ( this ).nextAll( 'div' ).toggle('fast');
    $ ( this ).toggleClass( 'close' );
    if ( fullEntryIsShown ) {
        // Eintrag ist bereits ausgeklappt, daher wird er eingeklappt und der Inhalt gelöscht.
        $ ( this ).nextAll( 'div' ).remove();
    } else {
        //
        var caller = $ ( this ); 
        var url = $ ( this ).attr("href");
        $.get(url, null , function ( responseData , statusText, responseObj ) {
            caller.after( $(responseData).find(".showEntry") );
        }, 'html' );
        
    }
}); 

// Handler für Klick auf "Resultate"
$( '.showResults' ).on('click', '.zahl', function (e) {
    e.preventDefault();
    var caller = $ ( this ); 
    var query = $ ( this ).attr("data-query");
    executeQuery(query);
});

// Handler für Klick auf alphabetische Liste für Autoren oder Werktitel
$('.suchOptionen a').click(function(e){
    e.preventDefault();
    var index = $(e.target).closest("li").attr("data-index");
    var term = $(e.target).text() + "*";
    executeQuery(index+"="+term);
});
 
var sup= $ ( 'div.schlagworte .sup' );
var showAll =  $ ( '#aO' ).click( 
  function ( ) { 
    $ ( '.schlagworte li li ol' ).show ();
    $ ( sup ).addClass( 'close' );     
    }
  );  
var closeAll =  $ ( '#aC' ).click( 
  function ( ) { 
    $ ( '.schlagworte li li ol' ).hide ();
    $ ( '.schlagworte .sup' ).removeClass( 'close' );     
    }
  ); 
 
}
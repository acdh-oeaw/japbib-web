$(document).ready(function() {

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

for (a in divs) { 
  $( divs[a] ).hide(); 
  $( divs[0] ).show(); 
  } 

for (i in go2s) {
$(go2s[i]).click(
  function () {  
    for (a in divs) { $( divs[a] ).hide(); } 
    $('#'+this.name ).show();
    }
  );
  }

//////// Find //////

var toggleAnd = $('.andOr').click(
  function() { if (this.innerHTML== 'AND') this.innerHTML='OR'; 
               else this.innerHTML= 'AND'; }
  );
  
var hideResults= $('.showResults').hide();
var resultTogglingLinks= $('.suchOptionen a').click(function(e){
  e.preventDefault();
  toggleResults($(this).attr('href'))});
function toggleResults(href) {  
  $('.showResults').hide('slow');
  $('.showResults ol').remove();
  var frameWork = $('.content .showResults').clone();
  $('.content .showResults').load(href, function(){
    var ajaxParts = $('.content .showResults .ajax-result'),
        searchResult = ajaxParts.find('.search-result > ol'),
        categoryFilter = ajaxParts.find('.categoryFilter > ol');
    $('.pageindex .schlagworte.showResults').replaceWith(categoryFilter);
    frameWork.find('#showList').append(searchResult);
    ajaxParts.replaceWith(frameWork);
    $('.showResults').show('slow');
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
    var params = $('#searchform1').serialize(),
        baseUrl = $('#searchform1').attr('action')
    toggleResults(baseUrl+'?'+params);
  }
}

//////// Schlagworte //////
  
$ ( '.schlagworte li li ol' ).hide ();
var as= $ ( '.schlagworte a' );
for (i in as) {
  as[i].innerHTML= Math.ceil(Math.random()*10000);
  }

var showSublist =  $ ( '.sup' ).click( 
  function ( ) { 
    $ ( this ).nextAll( 'ol' ).toggle('fast');
    $ ( this ).toggleClass( 'close' );     
    }
  ); 
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
 
});
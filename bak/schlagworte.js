$(document).ready(function() {

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

$(document).ready(function() { 

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
});
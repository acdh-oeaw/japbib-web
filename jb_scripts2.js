$(document).ready(function() {
  if (!window.__karma__) {
    jb_init(jQuery, CodeMirror, hasher, crossroads, URI)
  }
});

function jb_init($, CodeMirror, hasher, crossroads, URI) {
  var m = {},
      getResultsLock = false,
      getResultsErrorTracker = {
        originalStack: "",
        raisedErrors: []
      }

// Passwort für Testphasen

$('#psw').keypress(testOnReturn);
$('#testPw').click(allowTest);

function testOnReturn(e) {
  if (e.which === 13) {
    e.preventDefault();
    allowTest();
  }
}
function allowTest() {
  if ($('#psw').val().toLowerCase() === 'test') { 
    Cookies.set('test', 'passed', { expires: 14 });
    $( '#testScreen' ).hide();
  }
  else alert('Passwort erfragen bei bernhard.scheid@oeaw.ac.at');    
}  
if (Cookies.get('test') === 'passed')
    $( '#testScreen' ).hide();


  /*********************************************

    "About", etc. 

  **********************************************/

  // Handler fuer Seitenwechsel (BS)
  var mainPages = ['about', 'find', 'thesaurus', 'suchen'];
  var aboutSubpages = ['ziele', 'help', 'geschichte', 'bildnachweise', 'dokumentation', 'impressum'];

  function go2page(link) {
    $('.slide').hide();
    $('#' + link).show();
    $('.control').add($('#navbar_items a')).removeClass('hilite');
    $('#' + link + '_control').add($('#navbar_items a[href~="#' + link + '"]')).addClass('hilite');
    //fixWishlist(); // toggle position thesaurus wishlist, s.u.
  }

  function go2subPage(link) {
    go2page('about');
    document.body.scrollTop = // For Chrome, Safari and Opera
      document.documentElement.scrollTop = 0; // Firefox and IE 
    $.each($('#about .content div'), function() {
      if ($(this).is(':visible') && this.id !== link)
        $(this).fadeOut('slow', function() {
          $('#' + link).fadeIn('slow');
        });
    });
    $('#about .pageindex a').removeClass('here');
    $('#about .pageindex a[href~="#' + link + '"]').addClass('here');
  }
  mainPages.forEach(function(link) {
    crossroads.addRoute(link + '{?query}', function(query) {
      switch (link) {
        case 'thesaurus':
          break;
        case 'find':
        default:
          fillInSearchFrom(query);
      }
      go2page(link);
      doSearchOnReturn();
    });
    crossroads.addRoute(link, function(query) {
      go2page(link);
    });
  });

  function fillInSearchFrom(query) {
    $.each(query, function(key, value) {
      $('#searchform1 input[name="' + key + '"]').val(value);
    });
  }

  aboutSubpages.forEach(function(link) {
    crossroads.addRoute(link, function() {
      go2subPage(link);
    });
  });

  //Anfangszustand: 
  go2subPage('ziele');

  //setup crossroads
  crossroads.routed.add(console.log, console); //log all routes

  ////////////////////////////////////////

  //setup hasher
  function parseHash(newHash, oldHash) {
    crossroads.parse(newHash);
  }
  hasher.initialized.add(parseHash); //parse initial hash
  hasher.changed.add(parseHash); //parse hash changes
  hasher.init(); //start listening for history change

  /*********************************************

    "Suchen und Finden"

  **********************************************/

  // Anfangszustand
  var hideResults = $('.showResults').hide();

/**********************************************

// Suche auslösen
// Ausrichten der Suchparameter; Übergeben der Parameter (doSearchOnReturn)
// Daten abfragen (getResultsHidden)
// Fehlerprüfung (checkLock)
// Verzögerung emulieren (callbackAlwaysAsync)
// Treffer zuordnen und alten Inhalt ersetzen (onResultLoaded)
// falls Fehler gefunden, diese anzeigen (handleGetErrors)

/**********************************************/


// Suche auslösen:
//// s.a. a-href=#find;  onFetchMoreHits()

$('#searchInput1').keypress(searchOnReturn);

function searchOnReturn(e) {
  if (e.which === 13) {
    e.preventDefault();
    doSearchOnReturn();
  }
}

  // Handler fuer Resultate pro Seiten (paging) 
  $("#maximumRecords").change(function(e) {
    doSearchOnReturn(false); //Filter nicht erneuern
  });

  // Handler fuer sortby 
  $(document).on('change', '#sortBy', function(e) {
    var target = $(this),
      sortBy = target.val(),
      currentQuery = $('#searchInput1').val(),
      sortLessQuery = currentQuery.replace(/ sortBy .*$/, ''),
      newQuery = sortLessQuery + ' sortBy ' + sortBy;
    if (sortBy === '-') {
      return;
    }
    target.data("sortBy", sortBy);
    $('#searchInput1').val(newQuery);
    doSearchOnReturn(false); 
  });

function executeQuery(query) {
  $('#searchInput1').val(query);
  $('#suchtipps > div').hide();
  doSearchOnReturn();
  unselectDate();
}
m.executeQuery = executeQuery;

// Ausrichten der Suchparameter; Übergeben der Parameter:

var newFilter = true;

function doSearchOnReturn(optNewFilter, optStartRecord) {
  newFilter = optNewFilter === undefined ? true : optNewFilter;
  var startRecord = optStartRecord || 1,
      baseUrl = $('#searchform1').attr('action'),
      query = $('#searchform1 input[name="query"]').val(),
      sortBy = query.indexOf('sortBy') === -1 ?
        query.replace(/^([^=]+).*/, '$1') :
        query.replace(/^.*sortBy\s+(.*)$/, '$1');
  $('#searchform1 input[name="startRecord"]').val(startRecord);
  $('#searchform1 input[name="x-no-search-filter"]').val(!newFilter);
  $('#sortBy').val(sortBy);
  getResultsHidden(baseUrl + '?' + $('#searchform1').serialize());
};

m.doSearchOnReturn = doSearchOnReturn;

// Daten abfragen:

var resultsFramework;

function getResultsHidden(href) {
  checkLock('getResultsHidden()', getResultsLock, getResultsErrorTracker);
  var currentSorting = $('#sortBy').val();
  resultsFramework = resultsFramework || $('.content > .showResults').clone();
  if (newFilter) $('.showResults').hide('slow');
  else $('content > .showResults').hide('slow');
  $('.ladeResultate').fadeIn('slow');
  getResultsLock = true;
  $('.content > .showResults').load(href, function(unused1, statusText, jqXHR) {
    callbackAlwaysAsync(this, jqXHR, onResultLoaded, [statusText, jqXHR, currentSorting]);
  });
}

// Fehlerprüfung:

function checkLock(callerName, aLock, anErrorTracker) {
  if (aLock) {
    var raisedError = Error("Do not call " + callerName + " while a request is in progress!");
    anErrorTracker.raisedErrors.push(raisedError);
    throw raisedError;
  } else {
    try {
      throw Error('')
    } catch (e) {
      anErrorTracker.originalStack = e.stack.replace(/^Error.*/, '');
    }
  }
}

// Verzögerung emulieren:

function callbackAlwaysAsync(self, jqXHR, onResultLoaded, argumentsList) {
  /* chrome behaves synchronous here when the file is running from disk */
  //// XHR = XMLHttpRequest; s. ajax.js
  if (jqXHR.status === 0) {
    /* emulate a delay that will always occur if the result is fetched from the real server */
    setTimeout(function() {
      onResultLoaded.apply(self, argumentsList);
    }, 1000);
  } else {
    onResultLoaded.apply(self, argumentsList);
  }
}

// Treffer zuordnen und alten Inhalt ersetzen:

function onResultLoaded(statusText, jqXHR, currentSorting) {
  try {
    var ajaxParts = $('.content > .showResults .ajax-result'),
      ajaxPartsDiagnostics = $('.content > .showResults sru\\:diagnostics'),
      searchResult = ajaxParts.find('.search-result > ol'), 
      categoryFilter = newFilter ? 
        ajaxParts.find('.categoryFilter > ol'):
        $('.pageindex > .schlagworte.showResults').clone(),
      navResults = ajaxParts.find('.navResults'),
      frameWork = resultsFramework.clone();
    //frameWork.find('.showOptions select').val(currentSorting);
    if (statusText === 'success' && getResultsErrorTracker.raisedErrors.length === 0 && ajaxPartsDiagnostics.length === 0) {
      $('.pageindex .schlagworte.showResults').replaceWith(categoryFilter); 
      frameWork.find('#showList > .navResults').replaceWith(navResults);
      frameWork.find('#showList > ol').replaceWith(searchResult);
    } else {
      // wenn nicht alles in Ordnung...
      handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText), getResultsErrorTracker])
    }
    $('.content > .showResults').replaceWith(frameWork);
    $('.content > .showResults textarea.codemirror-data').each(function() {
      CodeMirror.fromTextArea(this, {
        readOnly: true,
        lineNumbers: true,
        foldGutter: true,
        gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"]
      });
    });
    $('.ladeResultate').fadeOut('slow');
    $('#find .schlagworte li li ol').hide(); //Anfangszustand bei neuer Abfrage
    if (newFilter) $('.showResults').show('slow', arrangeHitlist);
    else $('.content > .showResults').show('slow', arrangeHitlist); // arrangeHitlist = Treffernavigation (BS) s.u.     
  } finally {
    getResultsLock = false;
    newFilter = true;
  }
}

// falls Fehler gefunden, diese anzeigen:

function handleGetErrors(frameWork, status, htmlErrorMessage, anErrorTracker) {
  if (anErrorTracker.raisedErrors.length === 0) {
    frameWork.prepend($('<div class="ajax-error c' + (status - (status % 100)) + '" data-errorCode="' + status + '">').append('<span>Server returned: ' + status + '</span><br/>').append(htmlErrorMessage));
  } else {
    var errors = '<pre>Original call:\n' + anErrorTracker.originalStack + '</pre>';
    for (var i = 0; i < anErrorTracker.raisedErrors.length; i++) {
      var stack = anErrorTracker.raisedErrors[i].stack.replace(/^Error.*/, '');
      errors += '<pre>' + anErrorTracker.raisedErrors[i].toString() + '\n' + stack + '</pre>'
    }
    frameWork.prepend($('<div class="ajax-error concurrency">').append(errors));
  }
  anErrorTracker.raisedErrors = [];
}

  /*********************************************
    Gestalte das Feld "Suche"
  **********************************************/
  // Handler fuer .tipp (BS)
  $('.tipp')
    .attr('title', 'Tipp')
    .children().hide();
  $('#suchtipps > div').show();
  $(document).on('click', '.tipp', function() {
    $(this)
      //.toggleClass('q2x') 
      .children().slideToggle('slow');
    var title = 'Tipp';
    if ($(this).hasClass('q2x')) {
      title = 'Tipp ausblenden';
    }
    $(this).attr('title', title);
  });
  // Handler fuer suchOptionen (BS)
  // Navigation
  $('.examples td[data-index]').hide();
  //$('.examples td[data-index]:first').show();
  $('.examples th').click(function() {
    if ($(this).parent().hasClass('here')) {
      $('.examples').removeClass('here');
      $('.examples').animate({height: "1.6em"}, 'slow') ;
      $('.examples td[data-index]').fadeOut('slow');
    }
    else {
      $('.examples').removeClass('here');
      $('.examples td[data-index]').fadeOut('slow');  
      $(this).parent().addClass('here');
      $('.examples').animate({height: "6em"}, 'slow') ;
      $(this).siblings('td[data-index]').fadeIn('slow');   
    }
  });
  // Suche nach Datum  
  var years = $('.year a'),
    rangeSelected = false,
    startSelected = 0,
    endSelected = 0;

  function unselectDate() {
    $(years).removeClass('selected');
    rangeSelected = false;
    startSelected = 0;
    endSelected = 0;
  }
  $(document).on('click', '.year a', function(e) {
    e.preventDefault();
    //fruehere Auswahl aufheben
    if (rangeSelected === true) unselectDate();
    $(this).toggleClass('selected');
    //neue Gruppe auswaehlen
    //erste Auswahl
    $.each(years, function(i) {
      if ($(years[i]).hasClass('selected')) {
        startSelected = i;
        return false;
      }
    });
    //letzte Auswahl
    $.each($(years), function(i) {
      if ($(years[i]).hasClass('selected')) {
        endSelected = i;
      }
    });
    // Gruppe selektieren    
    if (startSelected < endSelected) {
      for (i = startSelected; i <= endSelected; i++) {
        $(years[i]).addClass('selected');
      }
      rangeSelected = true;
    }
    // Suche formulieren
    var inputQuery = $('#searchInput1').val();
    inputQuery = inputQuery.replace(/[and ]*date[=><]+[\d-and te=><]+/, '');
    if ($('.year .selected').length > 0) {
      var dateQuery = inputQuery ? ' and date' : 'date';
      if (startSelected === endSelected)
        dateQuery += '=' + (1980 + startSelected);
      else
        dateQuery += '>=' + (1980 + startSelected) + ' and date<=' + (1980 + endSelected);
      inputQuery += dateQuery;
    }
    $('#searchInput1').val(inputQuery);
  });
  // Suchhilfe
  $('#searchInput1').on('keyup', function() {
    var eingetippt = ($(this).val());
    var rex1 = /[=* "]([^=* "]{4})/;
    var rex2 = /^(?!auth|subj|titl)[^=* "]{4}/;
    var match = rex1.exec(eingetippt) || rex2.exec(eingetippt);
    var q = '';
    // Ergebnisse vor ..= ausschließen
    if (match && match[1])
      q = match[1];
    else if (match)
      q = match[0];
    if (q) {
      $('#searchHelp b').text(q);
      if ($('#searchHelp td').is(':hidden'))
        $('#searchHelp th').trigger('click');
    }
  });


  /*********************************************
    "Treffer"
  **********************************************/
  
  // Handler fuer positionieren und scrollen der Trefferliste << >> (BS)   

  var maxLeft,  
      posLeft,
      runTime; // scroll-Dauer     

  function arrangeHitlist() { // Funktion wird von onResultLoaded aufgerufen
    if ($('#hitRow') !== 'undefined') {
      var hits = $('#hitRow .hits'), //Treffer innerhalb der beweglichen hitRow
          hitsW = $('#hitRow').width(),
          FW = ($('.navResults').width() - $('.countResults').width()) / 2, // max. Weite fuer fenster    
          widthHere,    
          posHere,    
          centerHere,   
          spaceRightToHere;  
      if (FW < hitsW) { //Fenster kleiner als Hit-list         
        $('#fenster1').width(FW);
        $('.pull').css("visibility", "visible"); // Nav-Pfeile anzeigen
        //  hitRow  positionieren:
        maxLeft = FW - hitsW;
        if ($('#hitRow .here').length > 0) { 
          // wenn .here in hitRow
          widthHere = $('#hitRow .here').width();
          posHere = $('#hitRow .here').position().left + widthHere;
          spaceRightToHere = hitsW - posHere;
          centerHere = (FW - widthHere) / 2;
          if (posHere > FW) {
            // wenn .here außerhalb des Fensters
            posLeft =  centerHere < spaceRightToHere ? 
              centerHere - $('#hitRow .here').position().left :
              maxLeft;
          }
          else { 
            posLeft = 0;
          }
        } 
        if ($('.last.here').length > 0) {
          posLeft = maxLeft;
        } 
        if ($('.first.here').length > 0) {
          posLeft = 0;
        } 
      } 
      else { //Fenster größer als Hit-list
        // Nav-Pfeile verstecken
        $('#fenster1').width(hitsW);
        $('.pull').css("visibility", "hidden");
        //  hitRow  positionieren
        maxLeft = 
        posLeft =  0;
      }
      // hitRow in Hinblick auf .here verschieben 
      $('#hitRow').css('left', posLeft);
      //
      stylePull();       
    } 

    function stylePull() {
    // Navigationspfeile anpassen
      $('#pullLeft, #pullRight').addClass('active');
      if ($('#hitRow').position().left >= 0)
        $('#pullLeft').removeClass('active');
      if ($('#hitRow').position().left - 1 <= maxLeft)
        $('#pullRight').removeClass('active');
    }
    ///////// hitRow scollen /////////
    function pullHitRowBack() {
      if ($('#hitRow').position().left < 0) {
        runTime = $('#hitRow').position().left * -1.8;
        $('#hitRow').animate({
          left: 0
        }, runTime,  "linear", stylePull);
      } 
    }
    function pushHitRowForth() {
      if ($('#hitRow').position().left > maxLeft) {
        runTime = ( $('#hitRow').position().left - maxLeft) * 1.8;
        $('#hitRow').animate({
          left: maxLeft
        }, runTime,  "linear", stylePull);
      } 
    } 
    $(document).on('mousedown', '#pullLeft.active', pullHitRowBack );
    $(document).on('mousedown', ' #pullRight.active', pushHitRowForth );
    $(document).on('mouseup', '#pullLeft, #pullRight',
      function() {
        $('#hitRow').stop();
        stylePull();
      }
    );
  }

  $(document).on('click', '.hitList a.hits', onFetchMoreHits);

  function onFetchMoreHits(e) {
    e.preventDefault();
    var query = findQueryPartInHref($(this).attr('href'));
    doSearchOnReturn(false, query.startRecord);
  }

  /*********************************************
    Einzeleintrag
  **********************************************/
  // MODS/ LIDOS/  HTML umschalten (OS) (tlw. obsolet)
  $(document).on('change', '.showResults .showOptions select', function(e) {
    var target = $(e.target),
      format = target.val(),
      entry = target.closest(".showEntry");
    if (format === 'compact') {
      entry.addClass('compact');
    } else {
      entry.removeClass('compact');
    }
  });
  // Handler fuer toggleRecord (MODS und Lidos, BS) 
  $(document).on('click', '.toggleRecord', function(e) {
    var div = $(this).next("[class^=record]");
    div.toggle('slow', function(){
      // refresh needs to be called when CM is visible
      // so after the animation completetd
      refreshCM(div);
    });
// todo:
/*
    $.each($( this ).next('.record-html a.zahl'), function(e) {
      $( this ).append('...');
      // Abfrage der Trefferraten für interne Suchlinks
    });
*/
  });


  function refreshCM(div) {
    var editor = div.find('.CodeMirror')[0].CodeMirror;
    editor.refresh();
  } 

  /*********************************************

    "Thesaurus"

  **********************************************/
  var categoryFramework;
  var getCategoriesLock = false;
  var getCategoriesErrorTracker = {
    originalStack: "",
    raisedErrors: []
  }

  function loadCategory(href) {
    checkLock('loadCategory()', getCategoriesLock, getCategoriesErrorTracker);
    categoryFramework = categoryFramework || $('#thesaurus #showList').clone();
    $('#thesaurus #showList').hide('slow');
    getCategoriesLock = true;
    $('#thesaurus #showList').load('thesaurus', function(unused1, statusText, jqXHR) {
      callbackAlwaysAsync(this, jqXHR, onCategoryLoaded, [statusText, jqXHR]); //s.0.
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
      } else {
        handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText), getResultsErrorTracker])
      }
      $('#thesaurus #showList').replaceWith(frameWork);
      $('.ladeSchlagworte').hide();
      $('#thesaurus .schlagworte li li ol').hide(); //Anfangszustand bei Neuladen
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
  $('#facet-subjects').on('click', '.showResults a.aFilter', function(e) {
    e.preventDefault();
    //alert('ok');
    var query = findQueryPartInHref($(this).attr('href')),
      subject = query.query,
      currentQuery = $('#searchInput1').val(),
      newQuery = currentQuery === "" ? subject : currentQuery + " and " + subject; 
      /*,
      plusMinus = $(this).prevAll('.plusMinus');
    if (plusMinus.length === 1 && !plusMinusDependentIsShown(plusMinus)) {
      toggleNextSubtree.apply(plusMinus, [e]);
      setTimeout(function() {
        executeQuery(newQuery)
      }, 2000);
    } else {
      executeQuery(newQuery);
    }
    */
    executeQuery(newQuery);
  });

  function plusMinusDependentIsShown(aPlusMinus) {
    return $(aPlusMinus).hasClass("close")
  }
  // Handler für Klick auf (+) in Resultatliste
  $(document).on('click', '.results .plusMinus', openOrCloseDetails);

  function openOrCloseDetails(e) {
    e.preventDefault();
    if (plusMinusDependentIsShown(this)) {
      $(this).parent().nextAll('div').hide('slow');
    } else {
      $(this).parent().next('.showEntry').show('slow');
    }
    $(this).toggleClass('close');
  }
  // Handler für Klick auf "Resultate"
  $('.content').on('click', '.showResults a.zahl, .showResults a.stichwort', function(e) {
    e.preventDefault();
    var query = findQueryPartInHref($(this).attr('href')).query;
    executeQuery(query);
  });
  // Handler fuer Klick auf (x) in Einzeleintrag (BS)
  $(document).on('click', '.closeX', function() {
    var closestPlusMinus = $(this).closest('li').find(' .plusMinus ').trigger('click');
  });
  // Handler für Klick auf alphabetische Liste für Autoren oder Werktitel 
  $('.suchOptionen .abc a').click(function(e) {
    e.preventDefault();
    var index = $(e.target).closest("td").attr("data-index"),
      term = $(e.target).text() + "*",
      query = index + "=" + term;
    //executeQuery(index+"="+term); 
    $('#searchInput1').val(query);
  });
  $('#find a.code').click(function(e) {
    e.preventDefault();
    var query = $(this).text();
    //executeQuery(query);
    $('#searchInput1').val(query);
  });

  // Handler für Suchfeld:  Clear Search und search (BS)
  //$(document).on('keyup mouseup', 'body', toggleXQ );
  function toggleXQ() {
    if ($('#searchInput1').val().length < 1) {
      $('#clearSearch').hide();
      $('#doSearch').css({
        'opacity': '.1',
        'cursor': 'default',
        'background': 'transparent'
      });
    } else {
      $('#clearSearch').show();
      $('#doSearch').removeAttr("style");
    }
  }
  $(document).on('click', '#clearSearch', function() {
    $('.showResults').hide();
    $('#searchInput1').val('');
    hasher.prependHash = '';
    hasher.setHash('find');
    //toggleXQ();
  });
  $(document).on('click', '#doSearch', function(e) {
    e.preventDefault();
    var query = $('#searchInput1').val();
    if (query.length)
      executeQuery(query);
    //toggleXQ();
  });

  // Schlagwortbaum oeffnen und schliessen (BS)
  var plusMinus = '.schlagworte .plusMinus',
    ols = '#thesaurus .schlagworte li li ol';
  // Anfangszustand 
  $(plusMinus).removeClass('close');
  $(ols).hide();
  $(document).on('click', '#aO', function() {
    $(ols).show('slow');
    $(plusMinus).addClass('close');
  });
  $(document).on('click', '#aC', function() {
    $(ols).hide('slow');
    $(plusMinus).removeClass('close');
  });
  $(document).on('click', '.schlagworte .plusMinus', toggleNextSubtree);

  function toggleNextSubtree(e) {
    if (e.currentTarget !== e.target) {
      return;
    }
    $(this).nextAll('ol').toggle('slow');
    $(this).toggleClass('close');
  }

  /*
  // Handler fuer Kombinieren von Schlagworten im Thesaurus, #wishList (BS)
  var $wishList = $('#wishList'),
    ausgewaehlt = [],
    maxWishes = 3;
  $wishList.empty();

  function neueAuswahl(newTerm, newConj, remove) {
    var termIsNew = true,
      and
    conjIsNew = newConj ? true : false,
      newConj = newConj || 'and';
    if (ausgewaehlt.length)
      for (i in ausgewaehlt) {
        if (ausgewaehlt[i].term && ausgewaehlt[i].term == newTerm) {
          termIsNew = false;
          if (conjIsNew) ausgewaehlt[i].conj = newConj;
        }
      }
    if (termIsNew)
      ausgewaehlt.unshift({
        term: newTerm,
        conj: newConj
      });
    // auf 3 begrenzen
    if (ausgewaehlt.length > maxWishes)
      ausgewaehlt.pop();
    // Zeile etfernen
    if (remove) {
      for (i in ausgewaehlt)
        if (ausgewaehlt[i].term && ausgewaehlt[i].term == newTerm)
          ausgewaehlt.splice(i, 1);
    }
    // AND entfernen
    if (ausgewaehlt.length)
      ausgewaehlt[ausgewaehlt.length - 1].conj = '';

    // class=checked hinzufügen/entfernen
    var checked = [];
    $('#thesaurus .checked').removeClass('checked'); 
    $('#thesaurus .zahl').each(function() {
      for (i in ausgewaehlt) {
        if ($( this ).prevAll('.term').text() === ausgewaehlt[i].term)
        checked.push($( this ));
      }    
    });
    for ( i in checked) {      
     checked[i].addClass("checked"); 
    }

    baueListe();
  }

  function baueListe() {
    var $ue = $('#thesaurus h4');
    var newWishes = '';
    var newQ = '';
    $.each(ausgewaehlt, function(i, qObj) {
      newWishes += '<li><span><i class="fas fa-check-square" title="Auswahl löschen"></i>' +
        qObj.term +
        '</span><a class="andOr" title="Suche eingrenzen (AND)/ erweitern (OR)">' +
        qObj.conj +
        '</a></li>';
      newQ += 'subject="' + qObj.term + '" ' + qObj.conj + ' ';
    });
    newQ = encodeURIComponent(newQ);
    $wishList.empty();
    if (ausgewaehlt.length > 0) {
      $ue.text(' Ausgewählte Schlagworte ');
      $wishList
        .append('<ul>' + newWishes + '</ul>')
        .append('<a class="fas fa-search" id="abfrage" href="#find?query=' + newQ + '" title= "Abfrage auf der Suchseite">Abfrage</a>');
    } else {
      $ue.text('Schlagworte auswählen');
    }
  }
  // Auswahl entfernen
  $(document).on('click', '#wishList li > *', function() {
    var term = $(this).parent().clone().find('> a').remove().end().text();
    neueAuswahl($.trim(term), '', 1);
  });
  //  AND/OR/NOT[?]
  $(document).on('click', '.andOr', function(e) {
    e.preventDefault();
    var term = $(this).parent().clone().find('> a').remove().end().text(),
      conj = (this.innerHTML == 'and') ? 'or' :
      // ( this.innerHTML == 'OR')? 'NOT': 
      'and';
    neueAuswahl(term, conj);
  });
    */
    
  $(document).on('click', '#thesaurus .schlagworte a.zahl', function(e) {
    e.preventDefault();  
  });
  //in m gespeicherte Funktionen aufrufen:
  window.jb80 = m;
}
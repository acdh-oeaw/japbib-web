// For matomo. The matomo code snippet will make this
// a way to execute functions of the tracking system
var window = window || {};
var _paq = window._paq || [];

$(document).ready(function() {
    if (!window.__karma__) {
        jb_init(jQuery, CodeMirror, hasher, crossroads, URI)
    }
});

function jb_init($, CodeMirror, hasher, crossroads, URI) {
    var m = {}
      , getResultsLock = false
      , getResultsErrorTracker = {
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
            Cookies.set('test', 'passed', {
                expires: 14
            });
            $('#testScreen').hide();
        } else
            alert('Passwort erfragen bei bernhard.scheid@oeaw.ac.at');
    }
    if (Cookies.get('test') === 'passed')
        $('#testScreen').hide();
  
  /*Test ausschalten... */
        $('#testScreen').hide();
    /*********************************************************

        Handler fuer "Seitenwechsel" via #IDs
        und in href verpackte Queries 

    **********************************************************/ 

    var mainPages = ['about', 'find', 'thesaurus']
      , aboutSubpages = ['ziele', 'help', 'geschichte', 'bildnachweise', 'dokumentation', 'impressum'];

        //zeige elemente mit entsprechender ID (link), verstecke Geschwister (.slide) 
    function go2page(link) {
        $('.slide').hide();
        $('#' + link).show();
        $('.control').add($('#navbar_items a')).removeClass('hilite');
        $('#' + link + '_control').add($('#navbar_items a[href~="#' + link + '"]')).addClass('hilite');
        
        //Inhaltsverzeichnis der Seite
        fixPageindex();

        // toggle position thesaurus pageindex, s.u.
        
        // track a page view
        _paq.push(['setCustomUrl', URI().href()]);
        _paq.push(['trackPageView']);
    }

    function go2subPage(link) {
        go2page('about');
        document.body.scrollTop = // For Chrome, Safari and Opera
        document.documentElement.scrollTop = 0;        // Firefox and IE 
        
        $.each($('#about .content div'), function() {
            if ($(this).is(':visible') && this.id !== link)
                $(this).fadeOut('', function() {
                    $('#' + link).fadeIn('');
                });
        });
        $('#about .pageindex a').removeClass('here');
        $('#about .pageindex a[href~="#' + link + '"]').addClass('here');
        
        // track a page view
        _paq.push(['setCustomUrl', URI().href()]);
        _paq.push(['trackPageView']);
    }

            // übertrage query aus URL ins Suchfeld
    function fillInSearchFrom(query) {
            //trennt query-string bei "=" in "key" und "value"; input[name="query"] = Suchfeld (aka #searchInput1)
        $.each(query, function(key, value) {
            $('#searchform1 input[name="' + key + '"]').val(value);
        });
    }

        /*-----------------------------------------------------

        Create  new route pattern listeners, using "crossroads"
        Wenn ein href-Aufruf dem pattern entspricht, tritt der listener in Aktion

        --------------------------------------------------------*/ 

    function fromRoute() {
        _paq.push(['setReferrerUrl', URI().href()]);
    }

    mainPages.forEach(function(link) {
               //crossroads.addRoute sucht in hrefs nach dem pattern "mainPages[i]?query" 
               //und packt nachfolgende Werte in Variable "query" 
        crossroads.addRoute(link + '{?query}', function(query) {
                // schreibe query in Suchfeld:
        $.each(query, function(key, value) {
            $('#searchform1 input[name="' + key + '"]').val(value);
        });
                // gehe zur gesuchten Seite (find):
            go2page(link);
                // starte Suche:
            initSearch();
        });
            //pattern ohne "?"
        crossroads.addRoute(link, function() {
            go2page(link);
        });
    });

    

    aboutSubpages.forEach(function(link) {
        crossroads.addRoute(link, function() {
            go2subPage(link);
        });
    });

    //Anfangszustand: 
    go2subPage('ziele');

    ///////////// Standard calls für crossroads + hasher ////

    //setup crossroads, log all routes
    crossroads.routed.add(fromRoute);

    //setup hasher
    function parseHash(newHash, oldHash) {
        crossroads.parse(newHash);
    }
    hasher.initialized.add(parseHash); //parse initial hash
    hasher.changed.add(parseHash);     //parse hash changes
    hasher.init();                     //start listening for history change


    /*********************************************

      "Suchen und Finden"

    **********************************************/

    // Anfangszustand
    var hideResults = $('.showResults').hide();

    /*--------------------------------------------

    // Suche auslösen (passQuery2URL, passQuery2Searchform)
    // Ausrichten der Suchparameter; Übergeben der Parameter (initSearch)
    // Daten abfragen (getResultsHidden)
    // Fehlerprüfung (checkLock)
    // Verzögerung emulieren (callbackAlwaysAsync)
    // Treffer zuordnen und alten Inhalt ersetzen (onResultLoaded)
    // falls Fehler gefunden, diese anzeigen (handleGetErrors)

    ----------------------------------------------*/

    

    // Suche auslösen, nachdem Suchfeld ausgefüllt wurde: 

    $('#doSearch').click(function(e) {
            //Abfrage des Suchfeldes wird mit Parameter "?query=" in URL übertragen
            //Suche wird von "crossroads" gestartet (initSearch), sobald '?query' in URL gefunden wird (s.o.) 
            //initSearch liest Abfrage aus Suchfeld 
        e.preventDefault();  
        var query =  $('#searchInput1').val();
        if (query.length) {
            hasher.prependHash = '';
            hasher.setHash('find?query='+query);    
        }
    });

    $('#searchInput1, #inputAuthor, #inputTitle').keypress(function(e) {
        if (e.which === 13) {
            e.preventDefault();  
            $('#doSearch').trigger('click');
        }
    });

    // Suche auslösen, nachdem Filter geklickt  wurde: 

    function findQueryPartInHref(href) {
        // parse url into query string using URI.js library
        var parsed = URI(href)
          , conventionalQuery = parsed.query(true)
          , fragment = parsed.fragment()
          , query = conventionalQuery === {} ? conventionalQuery : URI(fragment).query(true);
        return query;
    }
    $('#facet-subjects').on('click', '.aFilter', function(e) {
        e.preventDefault();
        var filter = findQueryPartInHref($(this).attr('href')).query
          , currentQuery = $('#searchInput1').val().replace(/(.*)\s+sortBy.*$/,'$1')
          , newQuery = currentQuery.length ?  
            currentQuery + " and " + filter : filter;
        $('#searchInput1').val(newQuery);
        $('#doSearch').trigger('click');
    });

    // Handler fuer Resultate pro Seiten (paging) 
    $("#maximumRecords").change(function(e) { 
        if ($('#searchInput1').val() === '') {
            return;
            //keine Aktion bei leerem Suchfeld
        }
        initSearch(false);
            //Suche ohne Filter zu erneuern, mit neuem record-parameter 
    });

    // Handler fuer sortby 
    $("#sortBy").change(function(e) { 
        if ($('#searchInput1').val() === '') {
            return;
        }
        initSearch(false, 1, $(this).val());
            //Suche ohne Filter zu erneuern, mit neuem sort-parameter
    });

    // Ausrichten der Suchparameter; Übergeben der Parameter:

    var newFilter = true;

    function initSearch(optNewFilter, optStartRecord, sortByChoice) { 

        newFilter = optNewFilter === undefined ? true : optNewFilter;
        var startRecord = optStartRecord || 1
          , baseUrl = $('#searchform1').attr('action')
          , query = $('#searchInput1').val()
          , queryWithoutSort = query.replace(/ sortBy .*$/, '')
          , sortBy = $('#sortBy').val()
          , querySort
          , implicitSort
          , newQuery; 

         //  Sort-Parameter, der mit sortBy übergeben wurde
        if (query.indexOf('sortBy') !== -1) 
            querySort = query.replace(/^.*sortBy\s+(.*)$/, '$1');

        // wenn ein Query-Parameter auch ein Sort-Parameter ist
        $('#sortBy option').each(function() {
            if (query.indexOf($(this).val() + '=') !== -1) 
            implicitSort= $(this).val();
        });        

        sortBy= sortByChoice || querySort || implicitSort || sortBy; 
        $('#sortBy').val(sortBy);
          
        newQuery = sortBy === 'random' ? queryWithoutSort :
           queryWithoutSort + ' sortBy ' + sortBy;
        $('#searchInput1').val(newQuery);
        
        // versteckte Parameter ändern
        $('#searchform1 input[name="startRecord"]').val(startRecord);
        $('#searchform1 input[name="x-no-search-filter"]').val(!newFilter);

        // als ein querystring an "sru" senden 
        getResultsHidden(baseUrl + '?' + $('#searchform1').serialize());
    } 
    m.initSearch = initSearch;

    // Daten abfragen:

    var resultsFramework;

    function getResultsHidden(href) {
        checkLock('getResultsHidden()', getResultsLock, getResultsErrorTracker);
        var currentSorting = $('#sortBy').val();
        resultsFramework = resultsFramework || $('.content > .showResults').clone();
        if (newFilter)
            $('.showResults').hide('slow');
        else
            $('content > .showResults').hide('slow');
        $('.ladeResultate').fadeIn('slow');
        getResultsLock = true;

        //Anfage an Server mit load()
        $('.content > .showResults').load(href, function(unused1, statusText, jqXHR) {
            callbackAlwaysAsync(this, jqXHR, onResultLoaded, [statusText, jqXHR, currentSorting, href]);
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
            }, 500);
        } else {
            onResultLoaded.apply(self, argumentsList);
        }
    }

    // Treffer zuordnen und alten Inhalt ersetzen:

    function onResultLoaded(statusText, jqXHR, currentSorting, requestHref) {
        try {
            var ajaxParts = $('.content > .showResults .ajax-result')
              , ajaxPartsDiagnostics = $('.content > .showResults sru\\:diagnostics')
              , searchResult = ajaxParts.find('.search-result > ol')
              , categoryFilter = newFilter ? ajaxParts.find('.categoryFilter > ol') : $('.pageindex > .schlagworte.showResults').clone()
              , navResults = ajaxParts.find('.navResults')
              , frameWork = resultsFramework.clone();
            frameWork.find('.showOptions select').val(currentSorting);
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
            $('#find .schlagworte li li ol').hide();
            
            //Anfangszustand bei neuer Abfrage
            if (newFilter)
                $('.showResults').show('slow', arrangeHitlist);
            else
                $('.content > .showResults').show('slow', arrangeHitlist);
            // arrangeHitlist = Treffernavigation (BS) s.u.     
        } finally {
            getResultsLock = false;
            newFilter = true;
            var requestQuery = URI(requestHref).query(true),
                searchKeyword = requestQuery.query,
                searchCategory = requestQuery.query.replace(/^([^=]+)=.*/g, '$1');
            _paq.push(['trackSiteSearch',
            // Search keyword searched for
            searchKeyword,
            // Search category selected in your search engine. If you do not need this, set to false
            searchCategory,
            // Number of results on the Search results page. Zero indicates a 'No Result Search Keyword'. Set to false if you don't know
            $(navResults).find('.numberofRecords').text()
            ]);
        }
    }

    // falls Fehler gefunden, diese anzeigen:
    var errorPretext1 = 'Die Abfrage generierte einen Fehler.' + 
        '<br/>Versuchen Sie eine andere Abfrage oder informieren Sie die ' + 
        ' <a href="mailto:bernhard.scheid@oeaw.ac.at?subject=JB%2080,%20error&amp;body='+
        'Hier%20bitte%20Details%20der%20Fehlermeldung%20kopieren%20...'
      , errorPretext2 = '">Systemadministration</a>.';

    function handleGetErrors(frameWork, status, htmlErrorMessage, anErrorTracker) {
        if (anErrorTracker.raisedErrors.length === 0) {
            frameWork.prepend($('<div class="ajax-error c' + (status - (status % 100)) + '" data-errorCode="' + status + '">').append('<p class="pretext">'+
            errorPretext1 + errorPretext2 + '</p><span>Server returned: ' + status + '</span><br/>').append(htmlErrorMessage));
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
    // Handler fuer suchOptionen (BS)

    // Handler fuer .tipp
    $('.tipp').attr('title', 'Tipp').children().hide();
    $(document).on('click', '.tipp', function() {
        $(this).toggleClass('q2x').children().slideToggle('slow');
        var title = 'Tipp';
        if ($(this).hasClass('q2x')) {
            title = 'Tipp ausblenden';
        }
        $(this).attr('title', title);
    });

    //Felder schließen und leeren 
    $('.search.help').hide();
    $(document).on('click', '.searchNav i', function() {
        var id =  's_'+ $(this).attr('data-index'); 
        $('#'+id).slideToggle('fast'); 
        $('#'+id).find('input').val(''); 
    }); 

    $(document).on('click', '.hideSearch', function(e) {
        e.preventDefault();
        $(this).parents('.search').hide('slow'); 
    });
 
    // Suchhilfe Autor oder Titel
    function replaceSearchData(newInput, replacePattern, sortIndex) {
        var oldQuery = $('#searchInput1').val()
            .replace(replacePattern, '')
            .replace(/ sortBy .*$/, '')
            .replace(/(^\s*and | and\s*$)/g, '')
            .replace(/\s\s/g, ' ')
            .replace(/^\s+$/, '')
          , and = (oldQuery.length > 0 && newInput.length > 0) 
            ? ' and ' : ''
          , sortby = (sortIndex.match(/(author|date)/) && (oldQuery||newInput)) 
            ? ' sortBy '+sortIndex : ''; 
         
        $('#searchInput1').val(oldQuery+and+newInput+sortby);
    }
    $('.search.help input').on('keyup', function(){ 
        var index= $(this).attr('data-index')
          , newInput = $(this).val().replace(/\s+/,'').length > 0 ? index+'='+($(this).val())+'*' : ''
          , replacePattern = new RegExp('(\s*and |\s*)'+index+'=[^\\*]*\\*', 'g');

        replaceSearchData(newInput, replacePattern, index);   
    });
    
    $(document).on('click', '.search.examples .clearSearch', function() { 
       var input= $(this).parents('.search.examples').find('input');
       $( input ).val(''); 
       $( input ).trigger('keyup');  
    });

    // Suchhilfe für Datum  
    var years = $('.year a')
      , rangeSelected = false
      , startSelected = 0
      , endSelected = 0;

    function unselectDate() {
        $(years).removeClass('selected');
        rangeSelected = false;
        startSelected = 0;
        endSelected = 0;
    }

    function writeNewDate() {        
        var replacePattern = new RegExp('(\\s*and |\\s*)date.*?=\\d{4}', 'g')
        , dateQuery= 'date'
        , inputDateQuery
        , sortIndex= 'date';

        if (startSelected === endSelected)
            dateQuery += '=' + (1980 + startSelected);
        else
            dateQuery += '>=' + (1980 + startSelected) + ' and date<=' + (1980 + endSelected);
        
         
        if ($('.year .selected').length > 0) 
            inputDateQuery= dateQuery; 
        else 
          inputDateQuery=
          sortIndex= '';            
 
        replaceSearchData(inputDateQuery, replacePattern, sortIndex)
    }


    $(document).on('click', '.year a', function(e) {
        e.preventDefault();
        //fruehere Auswahl aufheben
        if (rangeSelected === true)
            unselectDate();
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
        //replace Date 
        writeNewDate();
    });

    $(document).on('click', '.year .clearSearch', function() { 
        unselectDate(); 
        writeNewDate();
    });

    /*********************************************
      "Treffer"
    **********************************************/

    // Handler fuer positionieren und scrollen der Trefferliste << >> (BS)   

    var maxLeft, posLeft, runTime;
    // scroll-Dauer     

    function arrangeHitlist() {
        // Funktion wird von onResultLoaded aufgerufen
        if ($('.hitRow') !== 'undefined') {
            var hits = $('.hitRow .hits'), //Treffer innerhalb der beweglichen hitRow
            hitsW = $('.hitRow').width(), FW = ($('.navResults').width() - $('.countResults').width()) / 2, // max. Weite fuer fenster  navResults  
            widthHere, posHere, centerHere, spaceRightToHere;
            if (FW < hitsW) {
                //Fenster kleiner als Hit-list         
                $('.fenster').width(FW);
                $('.pull').css("visibility", "visible");
                // Nav-Pfeile anzeigen
                //  hitRow  positionieren:
                maxLeft = FW - hitsW;
                if ($('.hitRow .here').length > 0) {
                    // wenn .here in hitRow
                    widthHere = $('.hitRow .here').width();
                    posHere = $('.hitRow .here').position().left + widthHere;
                    spaceRightToHere = hitsW - posHere;
                    centerHere = (FW - widthHere) / 2;
                    if (posHere > FW) {
                        // wenn .here außerhalb des Fensters
                        posLeft = centerHere < spaceRightToHere ? centerHere - $('.hitRow .here').position().left : maxLeft;
                    } else {
                        posLeft = 0;
                    }
                }
                if ($('.last.here').length > 0) {
                    posLeft = maxLeft;
                }
                if ($('.first.here').length > 0) {
                    posLeft = 0;
                }
            } else {
                //Fenster größer als Hit-list
                // Nav-Pfeile verstecken
                $('.fenster').width(hitsW);
                $('.pull').css("visibility", "hidden");
                //  hitRow  positionieren
                maxLeft = posLeft = 0;
            }
            // hitRow in Hinblick auf .here verschieben 
            $('.hitRow').css('left', posLeft);
            //
            stylePull();
            // $('#navResults2')
            if ($('#showList > .results > li').length > 9) {
                $('#navResults2').replaceWith($('.navResults').clone());
            }
        }

        function stylePull() {
            // Navigationspfeile anpassen
            $('.pullLeft, .pullRight').addClass('active');
            if ($('.hitRow').position().left >= 0)
                $('.pullLeft').removeClass('active');
            if ($('.hitRow').position().left - 1 <= maxLeft)
                $('.pullRight').removeClass('active');
        }
        ///////// hitRow scollen /////////
        function pullHitRowBack() {
            if ($('.hitRow').position().left < 0) {
                runTime = $('.hitRow').position().left * -1.8;
                $('.hitRow').animate({
                    left: 0
                }, runTime, "linear", stylePull);
            }
        }

        function pushHitRowForth() {
            if ($('.hitRow').position().left > maxLeft) {
                runTime = ($('.hitRow').position().left - maxLeft) * 1.8;
                $('.hitRow').animate({
                    left: maxLeft
                }, runTime, "linear", stylePull);
            }
        }
        $(document).on('mousedown', '.pullLeft.active', pullHitRowBack);
        $(document).on('mousedown', '.pullRight.active', pushHitRowForth);
        $(document).on('mouseup', '.pullLeft, .pullRight', function() {
            $('.hitRow').stop();
            stylePull();
        });
    }

    $(document).on('click', '.hitList a.hits', onFetchMoreHits);

    function onFetchMoreHits(e) {
        e.preventDefault();
        var query = findQueryPartInHref($(this).attr('href'));
        initSearch(false, query.startRecord);
    }

    /*********************************************
      Einzeleintrag
    **********************************************/
    
    // Handler fuer toggleRecord (MODS und Lidos, BS) 
    $(document).on('click', '.toggleRecord', function(e) {
        var div = $(this).next("[class^=record]");
        div.toggle('slow', function() {
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
            callbackAlwaysAsync(this, jqXHR, onCategoryLoaded, [statusText, jqXHR]);
            //s.0.
        });
    }

    function onCategoryLoaded(statusText, jqXHR) {
        try {
            var ajaxParts = $('#thesaurus #showList .ajax-result')
              , ajaxPartsDiagnostics = $('#thesaurus #showList sru\\:diagnostics')
              , categories = ajaxParts.find('ol.schlagworte')
              , frameWork = categoryFramework.clone();
            if (statusText === 'success' && getCategoriesErrorTracker.raisedErrors.length === 0 && ajaxPartsDiagnostics.length === 0) {
                frameWork.find('ol.schlagworte').replaceWith(categories);
            } else {
                handleGetErrors.apply(this, [frameWork, jqXHR.status, $.parseHTML(jqXHR.responseText), getResultsErrorTracker])
            }
            $('#thesaurus #showList').replaceWith(frameWork);
            $('.ladeSchlagworte').hide();
            $('#thesaurus .schlagworte li li ol').hide();
            //Anfangszustand bei Neuladen
            $('#thesaurus #showList').show('slow');
        } finally {
            getCategoriesLock = false;
        }
    }
    loadCategory();

    // Handler für Klick auf (+) in Resultatliste

    $(document).on('click', '.results .plusMinus', openOrCloseDetails);

    function openOrCloseDetails(e) {
        e.preventDefault();
        if ($(this).hasClass("close")) {
            $(this).parent().next('.showEntry').hide('slow');
        } else {
            $(this).parent().next('.showEntry').show('slow');
        }
        $(this).toggleClass('close');
    }

    // Handler fuer Klick auf (x) in Einzeleintrag (BS)
    $(document).on('click', '.closeX', function() {
        var closestPlusMinus = $(this).closest('li').find(' .plusMinus ').trigger('click');
    });

    // Handler für Klick auf alphabetische Liste für Autoren oder Werktitel 
    $('.suchOptionen .abc a').click(function(e) {
        e.preventDefault();
        var index = $(e.target).closest("td").attr("data-index")
          , term = $(e.target).text() + "*"
          , query = index + "=" + term;
        $('#searchInput1').val(query);
    });
    $('#find a.code').click(function(e) {
        e.preventDefault();
        var query = $(this).text();
        $('#searchInput1').val(query);
    });

    // Handler für Suchfeld:  Clear Search und search (BS)
    
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
    // Schlagwortbaum oeffnen und schliessen (BS)
    var plusMinus = '.schlagworte .plusMinus'
      , ols = '.schlagworte li li ol';

    // Anfangszustand 
    $(plusMinus).removeClass('close');
    $(ols).hide();

    // plusMinus am Beginn von Thesaurus
    $(document).on('click', '#aO', function() {
        $(ols).show('slow');
        $(plusMinus).addClass('close');
    });
    $(document).on('click', '#aC', function() {
        $(ols).hide('slow');
        $(plusMinus).removeClass('close');
    });

    // plusMinus im Schlagwortbaum
    $(document).on('click', '.schlagworte .plusMinus', toggleNextSubtree);

    function toggleNextSubtree(e) {
        if (e.currentTarget !== e.target) {
            return;
        }
        $(this).parent('.wrapTerm').nextAll('ol').toggle('slow');
        $(this).toggleClass('close');
    }

    //wishlist fixieren (BS)
    function fixPageindex() {
        var top = $('#wrapAbsolute').offset().top - 40;
        if ($(document).scrollTop() >= top) {
            $('#wrapFixed').css({
                'position': 'fixed',
                'top': 40 + 'px'
            });
        } else {
            $('#wrapFixed').css({
                'position': 'static',
                'top': 'auto'
            });
        }
    }
    $(document).on('scroll', fixPageindex);

    // Handler fuer Kombinieren von Schlagworten im Thesaurus, #wishList (BS)

    var wishList = $('#wishList')
      , maxWishes = 3
      , ausgewaehlt = [];

    wishList.empty();

    $('#chooseQuerymode input').change(function() {

        $('#chooseQuerymode .ausgewaehlt').removeClass('ausgewaehlt');
        $(this).parent().addClass('ausgewaehlt');

        // Ausgangssituation herstellen  
        ausgewaehlt = [];

        var hideTime = wishList.html() ? 'slow' : 0;
        wishList.hide('hideTime', function() {
            wishList.empty();
            wishList.show();
        })

        if ($('.kombinieren').length)
            $('.kombinieren').removeClass('kombinieren');
        if ($('.checked').length)
            $('.checked').removeClass('checked');

        if ($(this).val() === 'combinedSearch') {
            $('#thesaurus .schlagworte').addClass('kombinieren');
            $('#thesaurus .schlagworte .zahl').attr('title', 'für kombinierte Suche auswählen');
        } else {
            $('#thesaurus .schlagworte .zahl').attr('title', 'direkte Suche auf der Suchseite');
        }
    });

    $(document).on('click', '#thesaurus .kombinieren a.zahl', function(e) {
        // wird nur bei ".kombinieren" ausgelöst
        e.preventDefault();
        $(this).toggleClass('checked');
        var remove = $(this).hasClass('checked') ? false : true
          , subject = $(this).prevAll('.term:first').html()
          , id = $(this).attr("data-id");
        //zur raschen Identifizierung

        renewChecked(subject, remove, id);
    });

    function renewChecked(subject, remove, id) {
        // aktualisiere den Array  
        if (remove) {
            for (i in ausgewaehlt) {
                if (ausgewaehlt[i].term === subject)
                    ausgewaehlt.splice(i, 1);
            }
        } else {
            ausgewaehlt.unshift({
                term: subject,
                conj: 'and',
                id: id
            });
        }
        // auf 3 begrenzen
        if (ausgewaehlt.length > maxWishes)
            ausgewaehlt.pop();

        // letzte Konjunktion streichen  
        if (ausgewaehlt[ausgewaehlt.length - 1])
            ausgewaehlt[ausgewaehlt.length - 1].conj = '';

        //führe die neuen Arrayangaben aus
        renewWishlist();
    }

    function renewWishlist() {
        // aktualisiere die Wishlist und die gecheckten Zahlen
        var newWishes = ''
          , newQ = '';

        $('#thesaurus .zahl').removeClass('checked');

        $.each(ausgewaehlt, function(i, qObj) {
            // class=checked hinzufügen 
            $('.zahl[data-id="' + qObj.id + '"]').addClass('checked');

            newWishes += '<li><span data-name="' + qObj.id + '" class="ausgewaehlt" title="Auswahl löschen">' + qObj.term + '</span><a class="andOr" title="Suche eingrenzen (AND)/ erweitern (OR)">' + qObj.conj + '</a></li>';
            newQ += 'subject="' + qObj.term + '" ' + qObj.conj + ' ';
        });
        newQ = encodeURIComponent(newQ);

        // neue wishList schreiben

        var showTime = wishList.html() ? 0 : 'slow'
          , hitCount = calculateHits() ? '(' + calculateHits() + ' Treffer)' : '';
        wishList.empty();
        wishList.hide();

        if (ausgewaehlt.length > 0) {
            wishList.append('<p>Schlagworte (max. ' + maxWishes + '):</p><ul>' + newWishes + '</ul>').append(hitCount).append('<a class="fas fa-search" id="abfrage" href="#find?query=' + newQ + '" title= "Abfrage auf der Suchseite">Abfrage</a>');
        }
        wishList.show(showTime);
    }
    // Ergebnis berechnen
    function calculateHits() {
        //Anfrage an den Server schicken
        return 0;
    }

    // Auswahl entfernen
    $(document).on('click', '#wishList li *[data-name]', function() {
        var id = $(this).attr('data-name');
        $('.zahl[data-id="' + id + '"]').trigger('click');
    });
    //  AND/OR/NOT[?]
    $(document).on('click', '.andOr', function(e) {
        e.preventDefault();
        var id = $(this).parent().find('*[data-name]').attr('data-name')
          , conj = (this.innerHTML == 'and') ? 'or' : // ( this.innerHTML == 'OR')? 'NOT': 
        'and';
        for (i in ausgewaehlt)
            if (ausgewaehlt[i].id === id)
                ausgewaehlt[i].conj = conj;

        renewWishlist();
    }); 
    
    //in m gespeicherte Funktionen aufrufen:
    window.jb80 = m;
}

xquery version "3.0";

module namespace api = "http://acdh.oeaw.ac.at/japbib/xqueryui";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $api:database-LIDOS := "japbib4";
declare variable $api:database-MODS := "japbib_05";

declare %private function api:response($status, $msg, $payload) {
    element {$status} {(
        attribute {"msg"} {$msg},
        attribute {"results"} {count($payload)},
        $payload
    )}
};

(:~
 : Returns a file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web/xqueryui/{$file=.+\.(html|js|map|css|png|gif|jpg|jpeg|PNG|GIF|JPG|JPEG)}")
function api:file(
  $file as xs:string
) as item()+ {
  let $path := file:base-dir() || $file
  return (
    web:response-header(map { 'media-type': web:content-type($path) }),
    file:read-binary($path)
  )
};


    
declare 
    %rest:path("japbib-web/xqueryui/index.html")
    %output:method("xhtml")
    %output:omit-xml-declaration("no")
    %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")  
    %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
    %rest:GET 
function api:index() {
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>JapBib Experimental - Query endpoint</title>
            <script type="text/javascript" src="https://code.jquery.com/jquery-3.1.1.min.js"/>
            <link href="//fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css"/>
            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css"/>
            <link rel="stylesheet" type="text/css" media="screen" href="css/style.css"/>
        </head>
        <body>
            <div id="header"><a id="logo" href="http://acdh.oeaw.ac.at/"><img src="img/logo.png"/></a></div>
            <p style="color:red;">Please note: This service is experimental and may be subject to change any time.</p>
            <h2>JapBib 4 database</h2>
            <p>This is an <a href="https://www.w3.org/TR/xquery-30/">XQuery 3.0</a> endpoint for the JapBib 4 database. More information on XQuery can be found on <a href="https://de.wikipedia.org/wiki/XQuery">Wikipedia</a> or on <a href="http://www.w3schools.com/xsl/xquery_intro.asp">w3schools</a>.</p> 
            
            
            <h3>Query</h3>
            <div id="editor">//Verfasser</div>
            <form action="query" id="query-form" method="POST">
                <select name="db">
                    <option value="LIDOS" selected="selected">LIDOS Export</option>
                    <option value="MODS">MODS conversion</option>
                </select>
                <select name="returnRecord">
                    <option value="false">Show matching field only</option>
                    <option value="true">Show full bibliographic record</option>
                </select>
                <select name="max">
                    {for $i in (10, 20, 30, 50, 100, 200, 500) return <option value="{$i}">{(if ($i eq 100) then attribute selected {"selected"} else (), $i)}</option>}
                </select>
                <input name="startAt" type="hidden" value="1"/>
                <button type="submit">Run Query</button><i class="fa fa-spinner fa-spin"></i> (Or press Ctrl + Enter)
                <p>NB: The option <i>Show full bibliographic record</i> returns the full LIDOS record for any query - make sure that your query returns a node, not an atomic value, when using this.</p>
                <h3>Query Examples</h3>
                <p>Some example queries (click to insert into editor):</p>
                <ul class="examples" id="LIDOS-examples">
                    <li>List all Titles <a href="#"><code>//Titel</code></a></li>
                    <li>List all Authors containing a number (regex) <a href="#"><code>//Verfasser[matches(., '\d')]</code></a></li>
                    <li>List all publications about Japanese Identity <a href="#"><code>//LIDOS-Dokument[Deskriptoren = "Japanische Identität"]</code></a></li>
                    <li>List all publications after 1990 where "Verfasser" contains "Ackermann" (complicated, because the "Jahr" field not only contains numbers) <a href="#"><code>//LIDOS-Dokument[Jahr castable as xs:integer and xs:integer(Jahr) gt 1990 and contains(Verfasser, 'Ackermann')]</code></a></li>
                    <li>List all keywords (duplicates removed) <a href=""><code>for $i in //Deskriptoren
    group by $d := data($i)
    let $c := count($i)
    order by $c descending 
    return $d||" ("||$c||" occurences) &#10;"</code></a></li>
                </ul>
                <ul class="examples" id="MODS-examples">
                    <li>List all records with reference to a specific person: <a href="#"><code>let $name := "Rönsch" return //name[contains(namePart, $name)]</code></a></li>
                    <li>List all host publications (series or edited volumes) that contain unsure author information: <a href="#"><code>//relatedItem[comment()]</code></a>.</li> 
                </ul>
            </form>
            
            <h3>Results</h3>
            <div id="results-meta"/>
            <div id="results"/>
            
            <script src="js/ace-builds/src-min-noconflict/ace.js" type="text/javascript" charset="utf-8"/>
            <script src="js/ace-builds/src-min-noconflict/mode-xquery.js" type="text/javascript" charset="utf-8"/>
            <script src="js/ace-builds/src-min-noconflict/worker-xquery.js" type="text/javascript" charset="utf-8"/>
            <script type="text/javascript" src="js/query.js"/>
        </body>
    </html>
};

declare 
    %rest:path("japbib-web/xqueryui/query")
    %rest:POST("{$query}")
    %rest:query-param("startAt", "{$startAt}", 1)
    %rest:query-param("max", "{$max}", 100)
    %rest:query-param("db", "{$db}", "LIDOS")
    %rest:query-param("returnRecord", "{$returnRecord}", "false")
    %output:method("json")
    %output:json("format=jsonml")
function api:index($query, $startAt, $max, $db, $returnRecord as xs:boolean) {  
    let $db-name := 
        if ($db = "LIDOS") 
        then $api:database-LIDOS 
        else $api:database-MODS  
    let $hits := xquery:eval($query, map { '': db:open($db-name) }),
        $subseq := subsequence($hits, $startAt, $max),
        $results := 
            if ($returnRecord) 
            then $subseq/api:get-base-element(.) 
            else $subseq
    return <response>
                <hits>{count($hits)}</hits>
                <startAt>{$startAt}</startAt>
                <max>{$max}</max>
                <content>{fn:serialize($results, map { "method" : "xml", "indent" : "yes"})}</content>
           </response>  
};

(: Returns the base element from any node. In a LIDOS-Export this is the LIDOS-Dokument element, 
   in the MODS version this is a mods:mods element. :)
declare %private function api:get-base-element($elt as node()) as element() {
    ($elt/ancestor-or-self::LIDOS-Dokument,
    $elt/ancestor-or-self::mods:mods)[1]
}; 

xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "model.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";
import module namespace index = "japbib:index" at "index.xqm";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cache = "japbib:cache" at "cache.xqm";
import module namespace request = "http://exquery.org/ns/request";
import module namespace xqueryui = "http://acdh.oeaw.ac.at/japbib/xqueryui" at "xqueryui/xqueryui.xqm";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace sru = "http://www.loc.gov/zing/srw/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $api:SRU.SUPPORTEDVERSION := "1.2";
declare variable $api:HOSTNAME := "http://jb80.acdh.oeaw.ac.at";
declare variable $api:SRU.DATABASE := $model:dbname;
declare variable $api:SRU.DATABASETITLE := "JB 80: Deutschsprachige Japan-Bibliographie 1980–2000";

declare variable $api:path-to-thesaurus := "thesaurus.xml";
declare variable $api:thesaurus2html := "xsl/thesaurus2html.xsl";
declare variable $api:sru2html := "xsl/sru2html.xsl";

(:~
 : Returns a html or related file.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web/(?!(xqueryui)){$file=.+\.(html|js|map|css|png|gif|jpg|jpeg|PNG|GIF|JPG|JPEG)}")
function api:file($file as xs:string) as item()+ {
  let $path := file:base-dir()|| $file
  return if (file:exists($path)) then
  (
    web:response-header(map { 'media-type': web:content-type($path) }),
    file:read-binary($path)
  )
  else
  (
  <rest:response>
    <http:response status="404" message="{$file} was not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' was not found'}</title>
    <body>        
       <h1>{$file||' was not found'}</h1>
    </body>
  </html>
  )
};

(:~
 : Returns index.html on /.
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web")
function api:index-file() as item()+ {
  <rest:forward>index.html</rest:forward>
};

(:~
 : Return 403 on all other (forbidden files).
 : @param  $file  file or unknown path
 : @return rest response and binary file
 :)
declare
  %rest:path("japbib-web/{$file=[^/]+}")
function api:forbidden-file($file as xs:string) as item()+ {
  <rest:response>
    <http:response status="403" message="{$file} forbidden.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' forbidden'}</title>
    <body>        
       <h1>{$file||' forbidden'}</h1>
    </body>
  </html>
};

declare
  %rest:error('*')
  %rest:error-param("code", "{$code}")
  %rest:error-param("description", "{$description}")
  %rest:error-param("value", "{$value}")
  %rest:error-param("module", "{$module}")
  %rest:error-param("line-number", "{$line-number}")
  %rest:error-param("column-number", "{$column-number}")
  %rest:error-param("additional", "{$additional}")
function api:error-handler($code as xs:string, $description, $value, $module, $line-number, $column-number, $additional) as item()+ {
  <rest:response>
    <http:response status="500" message="{$description}.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$description}</title>
    <body>        
       <h1>{$description}</h1>
       {$code}:{$description} {$value} in {$module} at {$line-number}:{$column-number}:<br/>
       {$additional}
    </body>
  </html>
};

declare
  %rest:path("japbib-web/test-error.xqm")
function api:test-error() as item()+ {
  api:test-error('api:test-error')
};

declare
  %rest:path("japbib-web/test-error.xqm/{$error-qname}")
function api:test-error($error-qname as xs:string) as item()+ {
  error(xs:QName($error-qname))
};

declare
  %rest:path("japbib-web/runTests/{$file=[^/].+\.(xml)}")
function api:run-tests($file as xs:string) as item()+ {
  let $path := file:base-dir()|| $file
  return if (file:exists($path) and doc($path)/tests) then
  (
    web:response-header(map { 'media-type': 'text/xml'}),
    xquery:invoke('tests/runTests.xquery', map{'': doc($path)})
  )
  else
  (
  <rest:response>
    <http:response status="404" message="{$file} was not found.">
      <http:header name="Content-Language" value="en"/>
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  <html xmlns="http://www.w3.org/1999/xhtml">
    <title>{$file||' was not found'}</title>
    <body>        
       <h1>{$file||' was not found'}</h1>
    </body>
  </html>
  )
};

declare 
    %rest:path("japbib-web/sru")
    %rest:query-param("version", "{$version}")
    %rest:query-param("operation", "{$operation}", "explain")
    %rest:query-param("query", "{$query}")
    %rest:query-param("startRecord", "{$startRecord}", 1)
    %rest:query-param("maximumRecords", "{$maximumRecords}", 50)
    %rest:query-param("scanClause", "{$scanClause}")
    %rest:query-param("responsePosition", "{$responsePosition}", 1)
    %rest:query-param("maximumTerms", "{$maximumTerms}", 50)
    %rest:query-param("x-sort", "{$x-sort}", "text")
    %rest:query-param("x-style", "{$x-style}")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:sru($operation, $query as xs:string?, $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $scanClause, $maximumTerms, $responsePosition, $x-sort as xs:string, $x-style, $x-debug) {
    let $context := "http://jp80.acdh.oeaw.ac.at"
    let $ns := index:namespaces($context)
    return
        if (not($version)) then diag:diagnostics('param-missing', 'version') else
        if ($version != $api:SRU.SUPPORTEDVERSION) then diag:diagnostics('unsupported-version', $version) else
        switch($operation)
            case "searchRetrieve" return 
                if (not(exists($query))) then diag:diagnostics('param-missing', 'query') else 
                let $xcql := cql:parse($query)
                return 
                    if ($x-debug = 'false')
                    then api:searchRetrieve($xcql, $version, $maximumRecords, $startRecord, $x-style)
                    else $xcql
            case "scan" return api:scan($version, $scanClause, $maximumTerms, $responsePosition, $x-sort, $x-debug)
            default return api:explain()
};


declare 
    %rest:path("japbib-web/sru/searchRetrieve")
    %rest:query-param("version", "{$version}")
    %rest:query-param("startRecord", "{$startRecord}", 1)
    %rest:query-param("maximumRecords", "{$maximumRecords}", 50)
    %rest:query-param("x-style", "{$x-style}", 50)
    %rest:POST("{$xcql}")
    %rest:consumes("application/xml", "text/xml")
    %output:method("xml")
function api:searchRetrieve($xcql as item(), $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style) {
    let $accept := request:header("ACCEPT")
    let $context := $api:HOSTNAME
    let $ns := index:namespaces($context)
    
    let $xpath := cql:xcql-to-xpath($xcql, $context)
    let $sort-xpath := cql:xcql-to-orderExpr($xcql, $context)
    let $xqueryExpr := concat(
                        string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n||"';"),
                        if ($sort-xpath != '')
                        then
                            concat("for $m in ",$xpath," ", 
                                   "let $o := ($m/descendant-or-self::",$sort-xpath,")[1] ",
                                   "order by $o ",
                                   "return $m"
                            )
                        else $xpath
                    )
    let $results := 
        if ($xpath instance of xs:string and (not($sort-xpath) or $sort-xpath instance of xs:string)) then  
            try {
                xquery:eval(
                    $xqueryExpr
                    , map { '': db:open($model:dbname) }
                )
            } catch * {
                diag:diagnostics('general-error', 'xcql:'||fn:serialize($xcql)||' XQuery: '||$xqueryExpr)
            }
        else ()
    let $results-distinct := $results
    let $response := 
        if ($results instance of element(sru:diagnostics))
        then $results
        else api:searchRetrieveResponse($version, $results-distinct, $maximumRecords, $startRecord, $xqueryExpr)
    let $response-formatted :=
        if (some $a in tokenize($accept, ',') satisfies $a = ('text/html', 'application/xhtml+xml'))
        then 
            let $xsl := if ($x-style != '' and doc-available("xsl/"||$x-style)) then doc("xsl/"||$x-style) else doc($api:sru2html)
            return 
                (<rest:response>
                    <http:response>
                        <http:header name="Content-Type" value="text/html; charset=utf-8"/>
                    </http:response>
                </rest:response>,
                xslt:transform($response, $xsl, map{"xcql" : fn:serialize($xcql)}))
        else $response
    return 
        if ($xpath instance of xs:string)
        then $response-formatted
        else $xpath
};

declare %private function api:searchRetrieveResponse($version, $results, $maxRecords, $startRecord, $xpath) as element(){
    let $nor := count($results),
        $subs := subsequence($results, $startRecord, $maxRecords),
        $nextRecPos := if ($nor ge count($subs) + $startRecord) then count($subs) + $startRecord else ()
    return
    <sru:searchRetrieveResponse 
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
        xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/"
        xmlns:sru="http://www.loc.gov/zing/srw/">
        <sru:version>1.2</sru:version>
        <sru:numberOfRecords>{$nor}</sru:numberOfRecords>
        <sru:records>{
            for $r at $p in $subs 
            return
                <sru:record>
                    <sru:recordSchema>mods</sru:recordSchema>
                    <sru:recordPacking>XML</sru:recordPacking>
                    <sru:recordData>{$r}</sru:recordData>
                    <sru:recordNumber>{$p + $startRecord - 1}</sru:recordNumber>
                </sru:record>
        }</sru:records>
        {if ($nextRecPos)
        then <sru:nextRecordPosition>{$nextRecPos}</sru:nextRecordPosition>
        else ()}        
        <sru:extraResponseData>
            {if ($xpath instance of xs:string)
            then <XPath>{$xpath}</XPath>
            else ()}
            <subjects>{api:subjects($results)!<mods:topic>{map:get(., "topic")} ({map:get(., "items")})</mods:topic>}</subjects>
        </sru:extraResponseData>
    </sru:searchRetrieveResponse>
};


(:~ Returns a sru scan.
 : @param $version: required, must be equal to $api:SRU.SUPPORTEDVERSION
 : @param $scanClause: required, must be a known index
 : @param $responsePosition: which term should be the first in the list, defaults to 1
 : @param $maxumumTerms: number of terms in the list, defaults to 50
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information 
~:)
declare 
    %rest:path("japbib-web/sru/scan")
    %rest:query-param("version", "{$version}")
    %rest:query-param("scanClause", "{$scanClause}")
    %rest:query-param("responsePosition", "{$responsePosition}", 1)
    %rest:query-param("maximumTerms", "{$maximumTerms}", 50)
    %rest:query-param("x-sort", "{$x-sort}", "size")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:scan($version, $scanClause, $maximumTerms as xs:integer?, $responsePosition as xs:integer?, $x-sort as xs:string?, $x-debug) {
        if (not(exists($scanClause))) then diag:diagnostics("param-missing", "scanClause") else 
        if (not($version)) then diag:diagnostics("param-missing", "version") else
        if (exists(cache:scan($scanClause, $x-sort))) then cache:scan($scanClause, $x-sort) 
        else api:do-scan($scanClause, $maximumTerms, $responsePosition, $x-sort, $x-debug)
};

(:~
 : Caches a given sru scan.
 : @param $version: required, must be equal to $api:SRU.SUPPORTEDVERSION
 : @param $scanClause: required, must be a known index
 : @param $responsePosition: which term should be the first in the list, defaults to 1
 : @param $maxumumTerms: number of terms in the list, defaults to 50
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information
~:)
declare 
    %rest:PUT
    %rest:path("japbib-web/sru/scan")
    %rest:query-param("version", "{$version}")
    %rest:query-param("scanClause", "{$scanClause}")
    %rest:query-param("responsePosition", "{$responsePosition}", 1)
    %rest:query-param("maximumTerms", "{$maximumTerms}")
    %rest:query-param("x-sort", "{$x-sort}", "size")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %updating
function api:cache-scan($version, $scanClause, $maximumTerms as xs:integer?, $responsePosition as xs:integer?, $x-sort as xs:string?, $x-debug) {
    let $terms := api:do-scan($scanClause, (), $responsePosition, $x-sort, $x-debug)
    return cache:scan($terms, $scanClause, $x-sort)
};

(:~
 : Computes the scan
 : @param $scanClause: required, must be a known index
 : @param $responsePosition: which term should be the first in the list, defaults to 1
 : @param $maxumumTerms: number of terms in the list, defaults to 50
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information
~:)
declare %private function api:do-scan($scanClause, $maximumTerms, $responsePosition, $x-sort, $x-debug){
    let $context := $api:HOSTNAME
    let $ns := index:namespaces($context)
    let $map as element(map):= index:map($context)
    let $scanClauseParsed := api:parseScanClause($scanClause, $map),
        $scanClauseIndex :=  $scanClauseParsed/index 
    let $index-xpath := index:index-as-xpath-from-map($scanClauseIndex, $map, 'path-only'),
        $index-match := index:index-as-xpath-from-map($scanClauseIndex, $map, 'match-only')
    let $xpath := 
            if (exists($scanClauseParsed/relation))
            then cql:cql-to-xpath(xs:string($scanClause), $context)||"//"||$index-xpath||"/"||$index-match
            else
                if (some $x in ($index-xpath, $index-match) satisfies $x instance of element(sru:diagnostics)) 
                then ($index-xpath, $index-match)[self::sru:diagnostics] 
                else "//"||$index-xpath||"/"||$index-match
    return 
            if ($xpath instance of xs:string) then
                let $xquery :=  
                     concat(
                         string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n||"';"),
                         "for $t in ", $xpath, " 
                          group by $v := data($t)
                          let $c := count($t) 
                          order by ", if ($x-sort = 'text') then '$v ascending' else '$c descending', "
                          return 
                             <sru:term xmlns:sru='http://www.loc.gov/zing/srw/'>
                                 <sru:numberOfRecords>{$c}</sru:numberOfRecords>
                                 <sru:value>{$v}</sru:value>
                                 <sru:displayTerm>{$v}</sru:displayTerm>
                             </sru:term>"
                     )
                let $terms := try { 
                    xquery:eval($xquery, map { '': db:open($model:dbname) })
                } catch * {
                    diag:diagnostics('general-error', 'Error evaluating expression '||$xquery||' '||$err:description)
                }
                return 
                    if ($x-debug = "true") 
                    then <debug>{$xquery}</debug> else 
                    if ($terms instance of element(sru:diagnostics))
                    then $terms
                    else 
                        api:scanResponse($terms, $maximumTerms, $responsePosition)
            else $xpath
};

declare function api:parseScanClause($scanClause as xs:string, $map as element(map)) as element(scanClause) {
    if ($scanClause = $map//index/@key/data(.))
    then <scanClause><index>{$scanClause}</index></scanClause>
    else 
        if (matches($scanClause,$cql:modifierRegex))
        then 
            let $parsed := cql:parse($scanClause)
            return 
                if ($parsed instance of element(sru:diagnostics))
                then $parsed
                else <scanClause>{$parsed/*}</scanClause>
        else diag:diagnostics('general-error', 'Unparsed scanClause '||$scanClause) 
};

(:~
 : Wraps a (sub)sequence of sru:terms in a sru:scanResponse element.
 : @param $terms: the terms to be output
 : @param $maxumumTerms: number of terms in the list. If empty, all terms are returned (used for caching)
 : @param $responsePosition: which term should be the first in the list
~:)
declare %private function api:scanResponse($terms, $maximumTerms, $responsePosition){
    <sru:scanResponse xmlns:srw="//www.loc.gov/zing/srw/"
              xmlns:diag="//www.loc.gov/zing/srw/diagnostic/"
              xmlns:myServer="http://myServer.com/">
        <sru:version>{$api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:terms>{if (not($maximumTerms)) then $terms else subsequence($terms, $responsePosition, $maximumTerms)}</sru:terms>
    </sru:scanResponse>
};


declare 
    %rest:path("japbib-web/sru/explain")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:explain() {
    <sru:explainResponse xmlns:sru="//www.loc.gov/zing/srw/">
        <sru:version>{$api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:record>
        <sru:recordPacking>XML</sru:recordPacking>
        <sru:recordSchema>http://explain.z3950.org/dtd/2.1/</sru:recordSchema>
        <sru:recordData>
            <zr:explain xmlns:zr="http://explain.z3950.org/dtd/2.1/">
                <zr:serverInfo protocol="SRU" version="{$api:SRU.SUPPORTEDVERSION}" transport="http" method="GET POST">
                    <zr:host>{$api:HOSTNAME}</zr:host>
                    <zr:port>80</zr:port>
                    <zr:database>{$api:SRU.DATABASE}</zr:database>
                </zr:serverInfo>
                <zr:databaseInfo>
                    <title lang="en" primary="true">{$api:SRU.DATABASETITLE}</title>
                </zr:databaseInfo>
                {index:map-to-indexInfo()}
                {index:map-to-schemaInfo()}
                <zr:configInfo>
                    <zr:default type="numberOfRecords">1</zr:default>
                    <zr:setting type="maximumRecords">50</zr:setting>
                </zr:configInfo>
            </zr:explain>
        </sru:recordData>
    </sru:record>
</sru:explainResponse>

};

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
function api:taxonomy-as-xml() {
    doc($api:path-to-thesaurus)
};

declare 
    %rest:path("japbib-web/thesaurus")
    %rest:GET
    %rest:produces("text/html", "application/xml+xhtml")
    %output:method("xml")
function api:taxonomy-as-html() {
    xslt:transform(doc($api:path-to-thesaurus), doc($api:thesaurus2html))
};

declare %private function api:subjects($r){
    for $t in $r//mods:subject[not(@displayLabel)]/mods:topic
    let $v := data($t)
    group by $v
    return map {
        'topic' : $v, 
        'items' : count($t)
    } 
};
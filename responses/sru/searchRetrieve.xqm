xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/searchRetrieve";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace jobs = "http://basex.org/modules/jobs";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace request = "http://exquery.org/ns/request";
import module namespace prof = "http://basex.org/modules/prof";
import module namespace xslt = "http://basex.org/modules/xslt";
import module namespace l = "http://basex.org/modules/admin";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace http-util = "http://acdh.oeaw.ac.at/japbib/api/http" at "../http.xqm";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";

import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";
import module namespace u = "http://acdh.oeaw.ac.at/japbib/api/sru/util" at "util.xqm";
import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "scan.xqm";
import module namespace thesaurus = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "../thesaurus.xqm";
import module namespace _ = "urn:sur2html" at "../localization.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace zr = "http://explain.z3950.org/dtd/2.1/";

declare variable $api:force-xml-style := 'none';
declare variable $api:sru2html := $sru-api:path-to-stylesheets||"sru2html.xsl";
(: should provide a BaseX json direct XML representation:)
declare variable $api:sru2json := $sru-api:path-to-stylesheets||"sru2json.xsl";

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style) {
  api:searchRetrieve($query, $version, $maximumRecords, $startRecord, $x-style, false(), ())
};

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style, $x-debug as xs:boolean, $accept as xs:string?) {
  if (not(exists($query))) then diag:diagnostics('param-missing', 'query') else
  try {
  let $xcql-initial := cql:parse($query => replace('&amp;', '&amp;amp;')),
      $xcql := if (contains($query, "sortBy")) then $xcql-initial else
      (l:write-log('api:searchRetrieve forcing sortBy '||($xcql-initial//index)[1], 'DEBUG'), cql:parse($query||' sortBy '||($xcql-initial//index)[1]))
  return 
     if ($x-debug = true())
     then $xcql
     else api:searchRetrieveXCQL($xcql, $query, $version, $maximumRecords, $startRecord, $x-style, $accept)
  } catch * {
        diag:diagnostics('general-error', 'cql:'||fn:serialize($query)||'&#10;'||
          $err:description||'&#10;'||' '||$err:module||': '||$err:line-number||'&#10;'||
          $err:additional)        
  }
};

declare 
    %rest:path("japbib-web/sru/searchRetrieve")
    %rest:query-param("version", "{$version}")
    %rest:query-param("query", "{$query}", "")
    %rest:query-param("startRecord", "{$startRecord}", 1)
    %rest:query-param("maximumRecords", "{$maximumRecords}", 50)
    %rest:query-param("x-style", "{$x-style}", '')
    %rest:POST("{$xcql}")
    %rest:consumes("application/xml", "text/xml")
    %output:method("xml")
function api:searchRetrieveXCQL($xcql as item(), $query as xs:string, $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style as xs:string?) {
    let $accept := request:header("ACCEPT")
    return api:searchRetrieveXCQL($xcql, $query, $version, $maximumRecords, $startRecord, $x-style, $accept)
};

declare %private function api:searchRetrieveXCQL($xcql as item(), $query as xs:string, $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style as xs:string?, $accept as xs:string?) {
    let $context := $sru-api:HOSTNAME
    
    let $xpath := cql:xcql-to-xpath($xcql, $context),
        $xquerySortExpr := api:create-sort-expr($xcql, '$__hits__', $context, $xpath),
        $hits := try {
          l:write-log('start api:get-hits', 'DEBUG'),
          api:get-hits($xpath, $xquerySortExpr, $context, $startRecord + $maximumRecords),
          l:write-log('end api:get-hits', 'DEBUG')
        } catch diag:search-failed {
          diag:diagnostics('general-error', 'xcql:'||fn:serialize($xcql)||
          '&#10; XQuery: '||$xpath||'&#10;'||
          $err:description||'&#10;'||' '||$err:module||': '||$err:line-number||'&#10;'||
          $err:additional)
        }
    let $results := 
        if ($hits instance of element(sru:diagnostics)) then $hits
        else if (exists($hits) and $xpath instance of xs:string and exists($xquerySortExpr)) then
        try {
          l:write-log('start api:sort-hits '||count($hits/*), 'DEBUG'),
          api:sort-hits($hits,
          string-join(api:create-sort-expr($xcql, '($__hits__!(if (./*:n) then ./*:n!db:open-pre(../@name, .) else ./*:v/*))', $context, $xpath), ''),
          $context, $startRecord, $maximumRecords),
          l:write-log('end api:sort-hits', 'DEBUG')
        } catch diag:sort-failed {
          diag:diagnostics('general-error', 'xcql:'||fn:serialize($xcql)||
          '&#10; XQuery: '||$xpath||'&#10;'||string-join($xquerySortExpr, '')||'&#10;'||
          $err:description||'&#10;'||' '||$err:module||': '||$err:line-number||'&#10;'||
          $err:additional)
        }
        else (),
        
        $response := 
        if ($results instance of element(sru:diagnostics))
        then $results
        else api:searchRetrieveResponse($version, xs:integer(sum($hits/@count)), $results, $hits, $maximumRecords, $startRecord, api:create-search-expr($xpath, $xquerySortExpr)||'&#10;'||string-join($xquerySortExpr, ''), $xcql),
        $response-with-stats := if ($response instance of element(sru:searchRetrieveResponse)) then api:addStatScans($response) else $response,
        $log := l:write-log('api:searchRetrieveXCQL $accept := '||$accept||' $x-style := '||$x-style||' $response-with-stats instance of element(sru:searchRetrieveResponse) '||$response-with-stats instance of element(sru:searchRetrieveResponse) , 'DEBUG'),
        $json-style := tokenize($api:sru2json, '/')[last()],
        $response-formatted := 
         if ((some $a in tokenize($accept, ',') satisfies $a = ('text/html', 'application/xhtml+xml')) and 
            not($x-style = ($api:force-xml-style, $json-style)) and
            $response-with-stats instance of element(sru:searchRetrieveResponse))
        then api:create-html-response($response-with-stats, $xcql,
             $query, $version, $startRecord, $maximumRecords, $x-style)
        else if (some $a in tokenize($accept, ',') satisfies $a = ('application/json') or
                 $x-style eq $json-style) 
        then api:create-json-response($response-with-stats, $xcql,
             $query, $version, $startRecord, $maximumRecords, $x-style)
        else    (<rest:response>
                    <http:response>
                        <http:header name="Content-Type" value="application/xml; charset=utf-8"/>
                    </http:response>
                </rest:response>,
                $response-with-stats)  
    return 
        if ($xpath instance of xs:string)
        then $response-formatted
        else $xpath
};

declare %private function api:get-hits($xpath as xs:string, $xquerySortExpr as xs:string+, 
  $context as xs:string, $max as xs:integer) as element(db)* {
try {
let $getEntriesQuery := api:create-search-expr($xpath, $xquerySortExpr),
    $logXqueryExpr := l:write-log('api:searchRetrieveXCQL $getEntriesQuery := '||$getEntriesQuery
    ||'&#10;$u:basePath := '||$u:basePath||' $u:selfName := '||$u:selfName , 'DEBUG'),
    $hits-queries := $model:dbname!($getEntriesQuery => replace('$__db__', '"' || . || '"', 'q')),
    $entryList := u:evals($hits-queries, (), 'Q-searchRetrieve-'||$context, true())[*]
    (: , $_ := l:write-log('api:searchRetrieveXCQL $entryList := '||serialize(subsequence($entryList, 1, 5)) , 'DEBUG') :)
return $entryList
} catch * {
    error(xs:QName('diag:search-failed'), $err:code||' '||$err:description||' '||$err:module||': '||$err:line-number)
}
};

declare function api:create-search-expr($xpath as xs:string, $xquerySortExpr as xs:string+) as xs:string {
concat($xquerySortExpr[1],
       '(: declare variable $__db__ external; :)&#10;',                        
       'let $__hits__ := ', $xpath, '&#10;',
       $xquerySortExpr[2],
       'return <db xmlns="" name="{$__db__}" count="{count($__res__)}">{&#10;',
       '$__res__!(try { <n>{db:node-pre(.)}</n> } catch * { <v>{.}</v> })}</db>')  
};

declare function api:create-sort-expr($xcql as item(), $nodesExpr as xs:string, $context as xs:string, $xpath as xs:string) as xs:string* {
    let $sort-xpath := cql:xcql-to-orderExpr($xcql, $context)
    let $sort-index-key := $xcql//sortKeys/key[1]/index
    let $sort-index := if ($sort-index-key != '') then index:index-from-map($sort-index-key, index:map($context)) else () 
    let $max-sort-value := 
            switch ($sort-index/@datatype)
                case "xs:integer" return 99999
                default return "'ZZZZZZZ'"
return if (not($sort-xpath) or $sort-xpath instance of xs:string) then (concat(
                        string-join(index:namespaces($context)!("declare namespace "||./@prefix||" = '"||./@uri||"';&#10;"), ''),
                        "declare variable $__hits__ external;&#10;",
                        "declare variable $__startAt__ external;&#10;",
                        "declare variable $__max__ external;&#10;"),
                        if ($sort-xpath != '')
                        then
                            concat(
                                   "let $__res__ := for $m in ", $nodesExpr ,"&#10;", 
                                   switch ($sort-index/@datatype)
                                     case"xs:integer" return concat("  let $o := try { xs:integer(normalize-space(($m/",$sort-xpath,")[1]))
                                     catch err:FORG0001 {()}&#10;")
                                     default return concat("  let $o := normalize-space(($m/",$sort-xpath,")[1])[. ne '']&#10;"),
                                   "  order by ($o, ", $max-sort-value, ")[1] ",
                                   if ($sort-index/@coll) then "collation '"||$sort-index/@coll||"'&#10;" else "&#10;",
                                   "  return $m&#10;"
                            )
                        else "let $__res__ := $__hits__!(if (./*:n) then ./*:n!db:open-pre(../@name, .) else ./*:v/*)&#10;",
                        "return subsequence($__res__, $__startAt__, $__max__)!(copy $__hilighting_copy__ := document {.} modify ()&#10;",
                        "return ft:mark(", $xpath => replace('collection($__db__)', '$__hilighting_copy__', 'q'),", '_match_'))"
                    )
       else ()
};

declare %private function api:sort-hits($hits as element(db)+, $xquerySortExpr as xs:string, 
  $context as xs:string, $startAt as xs:integer, $max as xs:integer) as element()+ {
try {
let $logXqueryExpr := l:write-log('api:searchRetrieveXCQL $xquerySortExpr := '||$xquerySortExpr , 'DEBUG'),
    $sort-job := jobs:eval($xquerySortExpr, map {
          '__hits__': $hits,
          '__startAt__': $startAt,
          '__max__': $max}, map {
          'cache': true(),
          'id': 'S'||'-'||$context||'-'||jobs:current(),
          'base-uri': $u:basePath||'/S''-'||$context||'-'||'searchRetrieve.xq'}), $_ := jobs:wait($sort-job)
    return jobs:result($sort-job)
} catch * {
     error(xs:QName('diag:sort-failed'), $err:code||' '||$err:description||' '||$err:module||': '||$err:line-number)
}
};

declare %private function api:searchRetrieveResponse($version as xs:string, $nor as xs:integer, $results as item()*, 
    $hits as element(db)*, $maxRecords as xs:integer, $startRecord as xs:integer, $xpath as xs:string, $xcql as item()) as element(){
    let $nextRecPos := if ($nor ge count($results) + $startRecord) then count($results) + $startRecord else ()
    return
    <sru:searchRetrieveResponse 
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
        xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/"
        xmlns:sru="http://www.loc.gov/zing/srw/">
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:numberOfRecords>{$nor}</sru:numberOfRecords>
        <sru:records>{
            for $r at $p in $results 
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
            <XCQL>{$xcql}</XCQL>
            <subjects>{thesaurus:addStatsToThesaurus(prof:time(thesaurus:topics-to-map(if ($hits) then $hits else <db/>), false(), 'thesaurus:topics-to-map '))}</subjects>
        </sru:extraResponseData>
    </sru:searchRetrieveResponse>
};

declare %private function api:_addStatScans($response as element(sru:searchRetrieveResponse)) as element(sru:searchRetrieveResponse) {
    let $indexes := for $i in index:map-to-indexInfo()//zr:name return if ($i = ('cql.serverChoice', 'id', 'cmt', 'subject')) then () else $i,
        $scanClauses := api:get-scan-clauses($indexes, $response),
        $scanQueries := $scanClauses ! ``[import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "scan.xqm";
        declare namespace sru = "http://www.loc.gov/zing/srw/";
        let $scanResponse := scan:scan-filter-limit-response('`{. => replace("'", "''") => replace('&amp;', '&amp;amp;') (: highlighter fix " ' :)}`', 1, 1, 'text', (), (), false(), true())[1]
        return $scanResponse update {
             delete node sru:version,
             delete node sru:echoedScanRequest/* except sru:echoedScanRequest/sru:scanClause,
             delete node .//sru:extraTermData
          }]``
     (: , $log := for $q at $i in $scanQueries return l:write-log('api:addStatScan $q['||$i||'] := '||$q, 'DEBUG') :)
        , $scans := if (exists($scanQueries)) then u:evals($scanQueries, (), 'searchRetrieve-addStatScans', true()) else ()
    return $response update insert node $scans into ./sru:extraResponseData
};

(: declare %private function api:__addStatScans($response as element(sru:searchRetrieveResponse)) as element(sru:searchRetrieveResponse) {
    let $start := prof:current-ns(),
        $indexes := for $i in index:map-to-indexInfo()//zr:name return if ($i = ('cql.serverChoice', 'id', 'cmt', 'subject')) then () else $i,
        $scanClauses := api:get-scan-clauses($indexes, $response),
        $scanResponses := $scanClauses!scan:scan-filter-limit-response(., 1, 1, 'text', (), (), false(), true()),
        $scans := $scanResponses update {
             delete node sru:version,
             delete node sru:echoedScanRequest/* except sru:echoedScanRequest/sru:scanClause,
             delete node .//sru:extraTermData
          }
      , $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
        $log := l:write-log('Execution of '||count($scanClauses)||' scans for api:addStatScans took '||$runtime||' ms')
    return $response update insert node $scans into ./sru:extraResponseData
}; :)

declare %private function api:addStatScans($response as element(sru:searchRetrieveResponse)) as element(sru:searchRetrieveResponse) {
    $response
};

declare %private function api:get-scan-clauses($indexes as element(zr:name)+, $response as element(sru:searchRetrieveResponse)) as xs:string* {
let $context := $sru-api:HOSTNAME,
    $ns := index:namespaces($context),
    $queries := for $i in $indexes return ``[`{string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n/@uri||"';")}`
      declare variable $response external;
      $response//`{index:index-as-xpath-from-map($i, index:map($context), 'match')}` ! ('`{xs:string($i)}`=="'||normalize-space(replace(., '&quot;','\\&quot;'))||'"')]``
    (:, $log := for $q at $i in $queries return l:write-log('api:get-scan-clauses $q['||$i||'] := '||$q, 'DEBUG'):)
  return distinct-values(u:evals($queries, map { 'response': $response }, "searchRetrieve-get-scan-clauses", true())) 
};

declare %private function api:create-html-response($response as element(sru:searchRetrieveResponse),
$xcql as element(), $query as xs:string, $version as xs:string, $startRecord as xs:integer, $maximumRecords as xs:integer, $x-style as xs:string?) { 
let $formatted := api:xsl-transform(u:get-xml-file-or-default($sru-api:path-to-stylesheets||$x-style, $api:sru2html, $x-style != ''), $response, $xcql, $query, $version, $startRecord, $maximumRecords, $x-style)
return 
  (<rest:response>
      <http:response>
          <http:header name="Content-Type" value="text/html; charset=utf-8"/>
      </http:response>
  </rest:response>,
  $formatted)  
};

declare %private function api:create-json-response($response as element(sru:searchRetrieveResponse),
$xcql as element(), $query as xs:string, $version as xs:string, $startRecord as xs:integer, $maximumRecords as xs:integer, $x-style as xs:string?) {
let $formatted := api:xsl-transform(u:get-xml-file-or-default($sru-api:path-to-stylesheets||$x-style, $api:sru2html, $x-style != ''), $response, $xcql, $query, $version, $startRecord, $maximumRecords, $x-style)
return
  (<rest:response>
      <http:response>
          <http:header name="Content-Type" value="application/json; charset=utf-8"/>
      </http:response>
  </rest:response>,
  json:serialize($formatted, map {'format': 'direct', 'merge': 'yes', 'indent': 'no'}))  
};

declare %private function api:xsl-transform($xsl as document-node(), $response as element(sru:searchRetrieveResponse),
$xcql as element(), $query as xs:string, $version as xs:string, $startRecord as xs:integer, $maximumRecords as xs:integer, $x-style as xs:string?) as item() {
xslt:transform($response, $xsl,
  map:merge((
  map{"xcql" : fn:serialize($xcql),
      "query": $query,
      "version": $version,
      "startRecord": $startRecord,
      "maximumRecords": $maximumRecords,
      "operation": 'searchRetrieve',
      "base-uri-public": http-util:get-base-uri-public(),
      "base-uri": ""
  },
  if ($x-style) then map{"x-style": $x-style} else map{}
  )))  
};
xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/searchRetrieve";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace request = "http://exquery.org/ns/request";
import module namespace prof = "http://basex.org/modules/prof";
import module namespace map = "http://www.w3.org/2005/xpath-functions/map";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";

import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";
import module namespace scan = "http://acdh.oeaw.ac.at/japbib/api/sru/scan" at "scan.xqm";
import module namespace thesaurus = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "../thesaurus.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace zr = "http://explain.z3950.org/dtd/2.1/";

declare variable $api:sru2html := $sru-api:path-to-stylesheets||"sru2html.xsl";

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style) {
  api:searchRetrieve($query, $version, $maximumRecords, $startRecord, $x-style, 'false')
};

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style, $x-debug as xs:boolean) {
  if (not(exists($query))) then diag:diagnostics('param-missing', 'query') else 
  let $xcql := cql:parse($query)
  return 
     if ($x-debug = true())
     then $xcql
     else api:searchRetrieveXCQL($xcql, $query, $version, $maximumRecords, $startRecord, $x-style)
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
    let $context := $sru-api:HOSTNAME
    let $ns := index:namespaces($context)
    
    let $xpath := cql:xcql-to-xpath($xcql, $context)
    let $sort-xpath := cql:xcql-to-orderExpr($xcql, $context)
    let $sort-index-key := $xcql//sortKeys/index
    let $sort-index := if ($sort-index-key != '') then index:index-from-map($sort-index-key, index:map($context)) else () 
    let $max-sort-value := 
            switch ($sort-index/@datatype)
                case "xs:integer" return 99999
                default return "'ZZZZZZZ'"
            
    let $xqueryExpr := concat(
                        string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n||"';"),
                        if ($sort-xpath != '')
                        then
                            concat("for $m in ",$xpath," ", 
                                   "let $o := ($m/descendant-or-self::",$sort-xpath,")[1] ",
                                   "order by ($o, ", $max-sort-value, ")[1] ",
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
        else api:searchRetrieveResponse($version, $results-distinct, $maximumRecords, $startRecord, $xqueryExpr, $xcql),
        $response-with-stats := api:addStatScans($response)
    let $response-formatted :=
        if ((some $a in tokenize($accept, ',') satisfies $a = ('text/html', 'application/xhtml+xml')) and not($x-style eq 'none'))
        then 
            let $xsl := if ($x-style != '' and doc-available($sru-api:path-to-stylesheets||$x-style)) then doc($sru-api:path-to-stylesheets||$x-style) else doc($api:sru2html),
                $formatted := 
                xslt:transform($response-with-stats, $xsl,
                map:merge((
                map{"xcql" : fn:serialize($xcql),
                    "query": $query,
                    "version": $version,
                    "startRecord": $startRecord,
                    "maximumRecords": $maximumRecords,
                    "operation": 'searchRetrieve',
                    "base-uri-public": api:get-base-uri-public(),
                    "base-uri": api:get-base-uri()
                },
                if ($x-style) then map{"x-style": $x-style} else map{}
                )))
            return 
                (<rest:response>
                    <http:response>
                        <http:header name="Content-Type" value="text/html; charset=utf-8"/>
                    </http:response>
                </rest:response>,
                $formatted)
        else $response-with-stats
    return 
        if ($xpath instance of xs:string)
        then $response-formatted
        else $xpath
};

declare %private function api:searchRetrieveResponse($version, $results, $maxRecords, $startRecord, $xpath, $xcql) as element(){
    let $nor := count($results),
        $subs := subsequence($results, $startRecord, $maxRecords),
        $nextRecPos := if ($nor ge count($subs) + $startRecord) then count($subs) + $startRecord else ()
    return
    <sru:searchRetrieveResponse 
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:xcql="http://www.loc.gov/zing/cql/xcql/"
        xmlns:diag="http://www.loc.gov/zing/srw/diagnostic/"
        xmlns:sru="http://www.loc.gov/zing/srw/">
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
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
            {$xcql}
            <subjects>{thesaurus:addStatsToThesaurus(prof:time(thesaurus:topics-to-map($results), false(), 'thesaurus:topics-to-map '))}</subjects>
        </sru:extraResponseData>
    </sru:searchRetrieveResponse>
};

declare %private function api:addStatScans($response as element(sru:searchRetrieveResponse)) as element(sru:searchRetrieveResponse) {
    let $context := $sru-api:HOSTNAME,
        $indexes := index:map-to-indexInfo()//zr:name,
        $ns := index:namespaces($context),
        $responseDocument := document{$response},
        $scanClauses := for $i in $indexes return if ($i = ('cql.serverChoice', 'id')) then () else
             let $q := concat(string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n||"';"),
                    '//', index:index-as-xpath-from-map($i, index:map($context), 'match'))
             return distinct-values(xquery:eval($q, map { '': $responseDocument })) ! (xs:string($i)||'=="'||replace(., '&quot;','\\&quot;')||'"')
        , $scans := prof:time($scanClauses ! (scan:scan-filter-limit-response(., 1, 1, 'text', (), (), false(), true())[1]), false(), 'do scans ')
    return $response update insert node $scans into ./sru:extraResponseData
};

declare %private function api:get-base-uri-public() as xs:string {
    let $forwarded-hostname := if (contains(request:header('X-Forwarded-Host'), ',')) 
                                 then substring-before(request:header('X-Forwarded-Host'), ',')
                                 else request:header('X-Forwarded-Host'),
        $urlScheme := if ((lower-case(request:header('X-Forwarded-Proto')) = 'https') or 
                          (lower-case(request:header('Front-End-Https')) = 'on')) then 'https' else 'http',
        $port := if ($urlScheme eq 'http' and request:port() ne 80) then ':'||request:port()
                 else if ($urlScheme eq 'https' and not(request:port() eq 80 or request:port() eq 443)) then ':'||request:port()
                 else '',
        (: FIXME: this is to naive. Works for ProxyPass / to /exist/apps/cr-xq-mets/project
           but probably not for /x/y/z/ to /exist/apps/cr-xq-mets/project. Especially check the get module. :)
        $xForwardBasedPath := (request:header('X-Forwarded-Request-Uri'), request:path())[1]
    return $urlScheme||'://'||($forwarded-hostname, request:hostname())[1]||$port||$xForwardBasedPath
};

declare %private function api:get-base-uri() as xs:string {
    'http://localhost:8984'||request:path()
};
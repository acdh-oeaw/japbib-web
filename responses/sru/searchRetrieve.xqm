xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/searchRetrieve";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace request = "http://exquery.org/ns/request";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";

import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";
import module namespace thesaurus = "http://acdh.oeaw.ac.at/japbib/api/thesaurus" at "../thesaurus.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $api:path-to-stylesheets := "../../xsl/";
declare variable $api:sru2html := $api:path-to-stylesheets||"sru2html.xsl";

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style) {
  api:searchRetrieve($query, $version, $maximumRecords, $startRecord, $x-style, 'false')
};

declare function api:searchRetrieve($query as xs:string, $version as xs:string, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style, $x-debug as xs:string) {
  if (not(exists($query))) then diag:diagnostics('param-missing', 'query') else 
  let $xcql := cql:parse($query)
  return 
     if ($x-debug = 'false')
     then api:searchRetrieveXCQL($xcql, $version, $maximumRecords, $startRecord, $x-style)
     else $xcql
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
function api:searchRetrieveXCQL($xcql as item(), $version, $maximumRecords as xs:integer, $startRecord as xs:integer, $x-style) {
    let $accept := request:header("ACCEPT")
    let $context := $sru-api:HOSTNAME
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
        else api:searchRetrieveResponse($version, $results-distinct, $maximumRecords, $startRecord, $xqueryExpr, $xcql)
    let $response-formatted :=
        if (some $a in tokenize($accept, ',') satisfies $a = ('text/html', 'application/xhtml+xml'))
        then 
            let $xsl := if ($x-style != '' and doc-available($api:path-to-stylesheets||$x-style)) then doc($api:path-to-stylesheets||$x-style) else doc($api:sru2html)
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
            <subjects>{thesaurus:addStatsToThesaurus(api:subjects($results))}</subjects>
        </sru:extraResponseData>
    </sru:searchRetrieveResponse>
};

declare %private function api:subjects($r) as map(*) {
    map:merge(
        for $t in $r//mods:subject[not(@displayLabel)]/mods:topic
        let $v := data($t)
        group by $v
        return map:entry($v, count($t))
    )
};
xquery version "3.1";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/scan";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";

import module namespace cache = "japbib:cache" at "cache.xqm";
import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";

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
    let $context := $sru-api:HOSTNAME
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
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:terms>{if (not($maximumTerms)) then $terms else subsequence($terms, $responsePosition, $maximumTerms)}</sru:terms>
    </sru:scanResponse>
};
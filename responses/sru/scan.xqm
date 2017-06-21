xquery version "3.0";
module namespace api = "http://acdh.oeaw.ac.at/japbib/api/sru/scan";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xquery = "http://basex.org/modules/xquery";
import module namespace db = "http://basex.org/modules/db";
import module namespace l = "http://basex.org/modules/admin";
import module namespace diag = "http://www.loc.gov/zing/srw/diagnostic/" at "diagnostics.xqm";
import module namespace cql = "http://exist-db.org/xquery/cql" at "cql.xqm";

import module namespace cache = "japbib:cache" at "cache.xqm";
import module namespace index = "japbib:index" at "../../index.xqm";
import module namespace model = "http://acdh.oeaw.ac.at/webapp/model" at "../../model.xqm";
import module namespace sru-api = "http://acdh.oeaw.ac.at/japbib/api/sru" at "../sru.xqm";

declare namespace sru = "http://www.loc.gov/zing/srw/";
declare namespace fcs = "http://clarin.eu/fcs/1.0";

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
    %rest:query-param("x-filter", "{$x-filter}")
    %rest:query-param("x-mode", "{$x-mode}")
    %rest:query-param("x-debug", "{$x-debug}", "false")
    %rest:GET
    %rest:produces("text/xml")
    %output:method("xml")
    %updating
function api:scan($version, $scanClause, 
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode,
                  $x-filter, $x-debug as xs:boolean) {
    let $log := l:write-log('scan:scan', 'DEBUG'),
        $cached-scan := if ($x-mode eq "refresh") then () else cache:scan($scanClause, $x-sort),
        $ret := 
        if (not(exists($scanClause))) then diag:diagnostics("param-missing", "scanClause") else 
        if (not($version)) then diag:diagnostics("param-missing", "version") else
        if (exists($cached-scan)) then $cached-scan 
        else api:do-scan($scanClause, $maximumTerms, $responsePosition, $x-sort, $x-filter, $x-debug)
    return (db:output($ret), if (empty($cached-scan) or $x-mode eq 'refresh') then cache:scan($ret, $scanClause, $x-sort) else ())
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
    let $terms := api:do-scan($scanClause, (), $responsePosition, $x-sort, '', $x-debug)
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
declare %private function api:do-scan($scanClause, $maximumTerms, $responsePosition, $x-sort, $x-filter, $x-debug){
    let $log := l:write-log('api:do-scan $x-debug := '||$x-debug||' $scanClause := '||$scanClause, 'DEBUG'),
        $context := $sru-api:HOSTNAME,
        $ns := index:namespaces($context),
        $map as element(map):= index:map($context),
        $scanClauseParsed := api:parseScanClause($scanClause, $map),
        $log := l:write-log('api:do-scan $scanClauseParsed := '||serialize($scanClauseParsed), 'DEBUG'),
        $scanClauseIndex :=  $scanClauseParsed/index,
        $index-xpath := index:index-as-xpath-from-map($scanClauseIndex, $map, 'path-only'),
        $index-match := index:index-as-xpath-from-map($scanClauseIndex, $map, 'match-only'),
        $xpath_or_diagnostics := 
            if (some $x in ($index-xpath, $index-match) satisfies $x instance of element(sru:diagnostics)) 
            then ($index-xpath, $index-match)[self::sru:diagnostics] 
            else "//"||$index-xpath||"/"||$index-match,
        $xquery := if ($xpath_or_diagnostics instance of xs:string) then
                     concat(
                         string-join(for $n in $ns return "declare namespace "||$n/@prefix||" = '"||$n||"';"),
                         "for $t in ", $xpath_or_diagnostics, "
                          let $v := data($t)
                          group by $v
                          let $c := count($t) 
                          order by ", if ($x-sort = 'text') then '$v ascending' else '$c descending', "
                          return 
                             <sru:term xmlns:sru='http://www.loc.gov/zing/srw/' xmlns:fcs='http://clarin.eu/fcs/1.0'>
                                 <sru:numberOfRecords>{$c}</sru:numberOfRecords>
                                 <sru:value>{$v}</sru:value>
                                 <sru:displayTerm>{$v}</sru:displayTerm>
                             </sru:term>"
                     ) else '()',
        $terms_or_diagnostics := 
            if (not($xpath_or_diagnostics instance of xs:string)) then $xpath_or_diagnostics
            else try { 
                    xquery:eval($xquery, map { '': db:open($model:dbname) })
                } catch * {
                    diag:diagnostics('general-error', 'Error evaluating expression '||$xquery||' '||$err:description)
                },
        $ret :=
            if ($x-debug = true()) then <debug>{$xquery}</debug>
            else if ($terms_or_diagnostics instance of element(sru:diagnostics))
            then $terms_or_diagnostics
            else api:scanResponse($scanClauseParsed, $terms_or_diagnostics, $maximumTerms, $responsePosition, $x-filter)
    return $ret
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
declare %private function api:scanResponse($scanClauseParsed as element(scanClause), $terms as element(sru:term)*,
                                           $maximumTerms as xs:integer?, $responsePosition as xs:integer,
                                           $x-filter as xs:string?){
    let $complete-terms-list := <sru:terms>{$terms}</sru:terms>,
        $start-term-position := (count($complete-terms-list/*[.//sru:value eq $scanClauseParsed/term]/preceding-sibling::*) + 1) + (-$responsePosition + 1),
        $scan-clause := xs:string($scanClauseParsed),
        $numbered-terms := api:numberTerms($complete-terms-list, $maximumTerms, $start-term-position)
    return
    <sru:scanResponse xmlns:srw="//www.loc.gov/zing/srw/"
              xmlns:diag="//www.loc.gov/zing/srw/diagnostic/"
              xmlns:myServer="http://myServer.com/">
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
        {$numbered-terms}                  
        <sru:echoedScanRequest>
            <sru:scanClause>{$scan-clause}</sru:scanClause>
            <sru:maximumTerms>{$maximumTerms}</sru:maximumTerms>
            <fcs:x-filter>{$x-filter}</fcs:x-filter>
        </sru:echoedScanRequest>
    </sru:scanResponse>
};

declare %private function api:numberTerms($terms as element(sru:terms), $maximumTerms as xs:integer?,
                                          $start-term-position as xs:integer) as element(sru:terms) {
let $numbered-terms :=
    for $t at $pos in $terms/sru:term
    return $t update insert node   
        <sru:extraTermData>
           <fcs:position>{$pos}</fcs:position>
        </sru:extraTermData>
    after ./sru:displayTerm
return if (not($maximumTerms)) then $numbered-terms else <sru:terms>{subsequence($numbered-terms, $start-term-position, $maximumTerms)}</sru:terms>
};
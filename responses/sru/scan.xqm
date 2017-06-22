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
    let $log := l:write-log('scan:scan', 'DEBUG')
    return if (not(exists($scanClause))) then db:output(diag:diagnostics("param-missing", "scanClause")) else 
           if (not($version)) then db:output(diag:diagnostics("param-missing", "version"))
           else api:scan-filter-limit-response($scanClause, $maximumTerms, $responsePosition, $x-sort, $x-mode, $x-filter, $x-debug)
};

declare %updating %private function api:scan-filter-limit-response($scanClause as xs:string,  
                  $maximumTerms as xs:integer?, $responsePosition as xs:integer?,
                  $x-sort as xs:string?, $x-mode,
                  $x-filter, $x-debug as xs:boolean) {
   let $context := $sru-api:HOSTNAME,
       $map as element(map):= index:map($context),
       $scanClauseParsed := api:parseScanClause($scanClause, $map),
       $log := l:write-log('api:scan-filter-limit-response $scanClauseParsed := '||serialize($scanClauseParsed), 'DEBUG'),
       $scanClauseIndex :=  $scanClauseParsed/index,
       $cached-scan := if ($x-mode eq "refresh") then () else cache:scan($scanClauseParsed, $x-sort),
       $terms := if (empty($cached-scan) or $x-mode eq 'refresh') then api:do-scan($scanClauseParsed, $x-sort, $x-debug) else $cached-scan,
       $ret := if ($terms instance of element(sru:terms))
               then api:scanResponse($scanClauseParsed, $terms, $maximumTerms, $responsePosition, $x-filter)
               else $terms
   return (db:output($ret), if ($terms instance of element(sru:terms) and empty($cached-scan)) then cache:scan($terms, $scanClauseParsed, $x-sort) else ())
};

(:~
 : Computes the full scan scan
 : @param $scanClausePaarsed: required, translated to an XML snippet, must be a known index
 : @param $x-sort: sorting of the term list. Possible values: 'size' (number of occurences, default) or 'text' (alphabetically by the term)
 : @param $x-debug: do not return scan but show some debugging information
 : @return either element(sru:terms) or element(sru:diagnostics) or element(debug)
~:)
declare %private function api:do-scan($scanClauseParsed as element(scanClause), $x-sort as xs:string?,
                                      $x-debug as xs:boolean?) as element() {
    let $log := l:write-log('api:do-scan $x-debug := '||$x-debug||' $scanClauseParsed := '||serialize($scanClauseParsed), 'DEBUG'),
        $context := $sru-api:HOSTNAME,
        $map as element(map) := index:map($context), 
        $ns := index:namespaces($context),
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
                    let $terms :=
                    <sru:terms>
                        {xquery:eval($xquery, map { '': db:open($model:dbname) })}
                    </sru:terms>,
                        $numbered-terms := api:numberTerms($terms)
                    return $numbered-terms
                } catch * {
                    diag:diagnostics('general-error', 'Error evaluating expression '||$xquery||' '||$err:description)
                },
        $ret :=
            if ($x-debug = true()) then <debug>{$xquery}</debug>
            else $terms_or_diagnostics
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
declare %private function api:scanResponse($scanClauseParsed as element(scanClause), $terms as element(sru:terms),
                                           $maximumTerms as xs:integer?, $responsePosition as xs:integer,
                                           $x-filter as xs:string?){
    let $anchor-term :=
        switch($scanClauseParsed/relation)
            case "==" return $terms/*[.//sru:value eq $scanClauseParsed/term]
            case "=" return $terms/*[starts-with(.//sru:value, $scanClauseParsed/term)]
            case "contains" return $terms/*[contains(.//sru:value, $scanClauseParsed/term)]
            case "any" return $terms/*[contains(.//sru:value, $scanClauseParsed/term)]
            case () return $terms[1]
            default  return error(xs:QName('diag:unimplementedRelation'), "Don't know how to handle relation"||$scanClauseParsed/relation||" for scan"),
        $error := if (empty($anchor-term)) then error(xs:QName('diag:noAnchor'), 'Anchor term '||$scanClauseParsed/term||' was not found in scan using relation '||$scanClauseParsed/relation) else (),
        $start-term-position := (count($anchor-term/preceding-sibling::*) + 1) + (-$responsePosition + 1),
        $scan-clause := xs:string($scanClauseParsed)
    return
    <sru:scanResponse xmlns:srw="//www.loc.gov/zing/srw/"
              xmlns:diag="//www.loc.gov/zing/srw/diagnostic/"
              xmlns:myServer="http://myServer.com/">
        <sru:version>{$sru-api:SRU.SUPPORTEDVERSION}</sru:version>
        <sru:terms xmlns:sru='http://www.loc.gov/zing/srw/' xmlns:fcs='http://clarin.eu/fcs/1.0'>
        {subsequence($terms/sru:term, $start-term-position, $maximumTerms)}
        </sru:terms>
        <sru:echoedScanRequest>
            <sru:scanClause>{$scan-clause}</sru:scanClause>
            <sru:maximumTerms>{$maximumTerms}</sru:maximumTerms>
            <fcs:x-filter>{$x-filter}</fcs:x-filter>
        </sru:echoedScanRequest>
    </sru:scanResponse>
};

declare %private function api:numberTerms($terms as element(sru:terms)) as element(sru:terms) {
let $numbered-terms :=
    <sru:terms xmlns:sru='http://www.loc.gov/zing/srw/' xmlns:fcs='http://clarin.eu/fcs/1.0'>{
    for $t at $pos in $terms/sru:term
    return $t update insert node   
        <sru:extraTermData>
           <fcs:position>{$pos}</fcs:position>
        </sru:extraTermData>
    after ./sru:displayTerm}
    </sru:terms>
return $numbered-terms
};